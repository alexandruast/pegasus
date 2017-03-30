#!/bin/bash
set -e -o pipefail
DIR=$(cd `dirname $0` && pwd)
ENV_DIR='environments'
TFVARS='terraform.tfvars'
GLOBAL_TAG='00-global'
TERRAFORM='terraform'
TERRAGRUNT='terragrunt'
TERRAGRUNT_CONFIG='terraform.tfvars'
TERRAGRUNT_TEMPLATE='find_in_parent.tfvars'

show_usage () {
cat << EOF
    Usage:
      $(basename "$0") -env=<environment> -scope=<region> <action>
      $(basename "$0") -env=dev -scope=global plan
      $(basename "$0") -env=dev -scope=us-east-1 plan -target=module.aws-vpc
      $(basename "$0") -env=dev -scope=us-east-1 taint -module=aws-ec2-service-vpn aws_instance.host.0
EOF
}

if [ "$#" -lt 3 ]
  then
    echo "Missing arguments!"
    show_usage
    exit 1
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    debug)
      debug="true"
      shift 1;;
    -env=*)
      env="${1#*=}"
      shift 1;;
    -scope=*)
      scope="${1#*=}"
      shift 1;;
    -target=*)
      target="$1"
      shift 1;;
    -var:*)
      extra_var="-var ${1#*:}"
      shift 1;;
    -module=*)
      taint_module="$1"
      shift 1;;
    apply|destroy|output|plan|refresh|show|get|taint|release-lock)
      action="$1"
      shift 1;;
    *)
      case $action in
        output)
          if [ ! "$output_param" = "" ]; then
            echo "Only one output parameter allowed!" >&2
            show_usage
            exit 1
          fi
          output_param=$1
          ;;

        taint)
          if [ ! "$taint_resource" = "" ]; then
            echo "Only one taint resource allowed!" >&2
            show_usage
            exit 1
          fi
          taint_resource=$1
          ;;

        *)
          echo "Unknown option: $1" >&2
          show_usage
          exit 1
          ;;
      esac
      shift 1;;
  esac
done

# Are required tools installed?
for tool in \
    "${TERRAFORM} version" \
    "${TERRAGRUNT} -v"
  do
      ${tool} >/dev/null 2>&1 || {
        echo "Missing ${tool}, install it!"
        exit 1
      }
done

case $scope in
  global|${GLOBAL_TAG})
    destination='global'
    scope=${GLOBAL_TAG}
    ;;
  *)
    destination='region'
    region=$scope
    ;;
esac

# Check if there is a valid tfvars configuration in destination directory
[ -f "$DIR/${ENV_DIR}/${env}/$scope/$TFVARS" ] || {
  printf '%s\n%s\n' "$TFVARS file missing in $DIR/${ENV_DIR}/${env}/$scope" \
         "Adjust the scope or create one in $DIR/${ENV_DIR}/${env} directory."
  exit 1;
}

global_tfvars="${DIR}/${ENV_DIR}/${env}/${GLOBAL_TAG}/${TFVARS}"
runtime_tfvars="$DIR/${ENV_DIR}/${env}/$scope/$TFVARS"
global_remote_state_key="terraform-${GLOBAL_TAG}.tfstate"
remote_state_key="terraform-$scope.tfstate"

aws_access_key=$( \
  sed -e 's/[[:space:]]*=[[:space:]]*/=/g' \
  ${global_tfvars} \
  | grep '^aws_access_key=' \
  | cut -d'=' -f2 \
  | tr -d '"' \
)

remote_state_bucket=$( \
  sed -e 's/[[:space:]]*=[[:space:]]*/=/g' \
  ${global_tfvars} \
  | grep '^remote_state_bucket=' \
  | cut -d'=' -f2 \
  | tr -d '"' \
)

dynamo_db_terragrunt_locks=$( \
  sed -e 's/[[:space:]]*=[[:space:]]*/=/g' \
  ${global_tfvars} \
  | grep '^dynamo_db_terragrunt_locks=' \
  | cut -d'=' -f2 \
  | tr -d '"' \
)

global_region=$( \
  sed -e 's/[[:space:]]*=[[:space:]]*/=/g' \
  ${global_tfvars} \
  | grep '^global_region=' \
  | cut -d'=' -f2 \
  | tr -d '"' \
)

export AWS_ACCESS_KEY_ID=${aws_access_key}
export TF_VAR_aws_access_key=${aws_access_key}
export TF_VAR_remote_state_bucket=${remote_state_bucket}
export TF_VAR_global_remote_state_key=${global_remote_state_key}
export TF_VAR_dynamo_db_terragrunt_locks=${dynamo_db_terragrunt_locks}
export TF_VAR_global_region=${global_region}
export TF_VAR_region=${region}
export TF_VAR_global_tag=${GLOBAL_TAG}
export TF_VAR_remote_state_key=${remote_state_key}

case $action in
  get|release-lock)
    executor=$TERRAGRUNT
    args="$action ../../$destination"
    ;;
  output)
    # Output does not need any parameters and is handled by terraform directly
    executor=$TERRAFORM
    args="$action $output_param"
    ;;
  taint)
    # Taint is handled by terraform directly
    executor=$TERRAFORM
    args="$action $taint_module $taint_resource"
    ;;
  apply|destroy|plan|refresh|show)
    executor=$TERRAGRUNT
    # Is target specified to terraform? Example: -target=module.vpc
    if [ "$target" = "" ]; then
      args="$action ${extra_var} -var-file=$runtime_tfvars ../../$destination"
    else
      args="$action $target ${extra_var} -var-file=$runtime_tfvars ../../$destination"
    fi
    ;;
esac

# Create terragrunt working dir
if [ ! -f "$DIR/$TERRAGRUNT/$scope/$TERRAGRUNT_CONFIG" ]; then
  mkdir -p $DIR/$TERRAGRUNT/$scope
  cp $DIR/$TERRAGRUNT/$TERRAGRUNT_TEMPLATE $DIR/$TERRAGRUNT/$scope/$TERRAGRUNT_CONFIG
fi

if [ ! "$debug" = "" ]; then
  echo "cd $DIR/$TERRAGRUNT/$scope && $executor $args"
  exit 0
fi

cd $DIR/$TERRAGRUNT/$scope

$executor $args 2>&1 | tee $executor.log || {
  # Modules may need to be downloaded first
  grep "Error downloading modules:" $executor.log >/dev/null && {
    get_args="get ../../$destination"
    $executor $get_args && $executor $args 2>&1 | tee $executor.log
  }
}
