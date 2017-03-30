#!/bin/bash
set -e
DIR=$(cd "`dirname $0`" && pwd)
ENV_DIR='environments'
TFVARS='terraform.tfvars'
GLOBAL_TAG='00-global'
TERRAFORM='terraform'
TERRAGRUNT='terragrunt'
MY_IP=`curl ifconfig.co 2> /dev/null`

show_usage () {
cat << EOF
    Usage:
      $(basename "$0") -env=<environment> -region=<region> <host_group>
      $(basename "$0") -env=dev -region=us-east-1 management
      $(basename "$0") -env=dev -region=us-east-1 management force
      $(basename "$0") -env=dev -region=us-east-1 compute debug
EOF
}

if [ "$#" -lt 2 ]
  then
    echo "Missing arguments!"
    show_usage
    exit 1
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    force)
      force=true
      shift 1;;
    debug)
      debug="-vvv"
      shift 1;;
    -env=*)
      env="${1#*=}"
      shift 1;;
    -region=*)
      region="${1#*=}"
      shift 1;;
    vpn|management|compute|compute_c)
      host_group_name="$1"
      shift 1;;
    *)
      echo "Unknown option: $1" >&2
      show_usage
      exit 1
  esac
done

# Are required tools installed?
for tool in \
    "${TERRAFORM} version" \
    "${TERRAGRUNT} -v" \
    "jq --version"
  do
      ${tool} >/dev/null 2>&1 || {
        echo "Missing ${tool}, install it!"
        exit 1
      }
done

# Check if there is a valid tfvars configuration in destination directory
[ -f "$DIR/$ENV_DIR/$env/$region/$TFVARS" ] || {
  printf '%s\n%s\n' "$TFVARS file missing in $DIR/$ENV_DIR/$env/$region" \
         "Adjust the scope or create one in $DIR/$ENV_DIR/$env directory."
  exit 1;
}

global_tfvars="$DIR/$ENV_DIR/$env/$GLOBAL_TAG/$TFVARS"
export AWS_ACCESS_KEY_ID=$(grep 'aws_access_key' $global_tfvars | tr -d ' "' | cut -d'=' -f2)

cd $DIR/$TERRAGRUNT/$region
datacenter=$region
security_group_id=$($TERRAFORM output ec2_ssh_security_group_id)
consul_hosts=$($TERRAFORM output -json ec2_management_private_ips | jq -c '.value')

# Might fail if already there
aws ec2 authorize-security-group-ingress \
  --group-id $security_group_id \
  --protocol tcp \
  --port 22 \
  --cidr ${MY_IP}/32 \
  --region $region || echo false:authorize-security-group-ingress

hosts=$($TERRAFORM output -json ec2_${host_group_name}_public_ips | jq -c '.value'| tr -d '"[]'),

cd $DIR
ANSIBLE_HOST_KEY_CHECKING=False \
  ansible-playbook -u ubuntu \
  -e force_install=${force:=false} ${debug:="-e debug=false"} \
  -e datacenter=$datacenter \
  -e host_group_name=$host_group_name \
  -e "{\"consul_hosts\":$consul_hosts}" \
  -e mongodb_uri_vpn=$([ ! "$MONGODB_URI_VPN" = "" ] && echo $MONGODB_URI_VPN || echo "mongodb://localhost:27017/pritunl") \
  -i $hosts \
  --module-path=./ansible/roles \
  ./ansible/${host_group_name}.yml

aws ec2 revoke-security-group-ingress \
  --group-id $security_group_id \
  --protocol tcp \
  --port 22 \
  --cidr ${MY_IP}/32 \
  --region $region || echo false:authorize-security-group-ingress
