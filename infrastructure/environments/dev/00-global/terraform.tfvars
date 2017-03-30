/* We do not use profiles anymore, because it's a local thing
   Use AWS_SECRET_ACCESS_KEY/AWS_SESSION_TOKEN instead
   http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html */

aws_access_key = "<your_access_key_here>"
global_region = "us-east-1"
infrastructure = "demo"
environment = "dev"
remote_state_bucket = "infrastructure-states-demo-dev-95a36199"
dynamo_db_terragrunt_locks = "infrastructure-terragrunt-locks"
domain = "demo-01.site"

ec2_user_data = "../../artifacts/user_data_ubuntu.sh"
ec2_public_key = "ssh-rsa <your_ssh_public_key_here>"

host_group_vpn = {
  name = "vpn"
  iam_role_template_file = "../../artifacts/iam-role-sts-assume.json"
  iam_policy_template_file = "../../artifacts/iam-policy-ec2-describe-instances.json"
}

host_group_management = {
  name = "management"
  iam_role_template_file = "../../artifacts/iam-role-sts-assume.json"
  iam_policy_template_file = "../../artifacts/iam-policy-vault-access.json"
}

host_group_compute = {
  name = "compute"
  iam_role_template_file = "../../artifacts/iam-role-sts-assume.json"
  iam_policy_template_file = "../../artifacts/iam-policy-ec2-describe-instances.json"
}

host_group_compute_c4 = {
  name = "compute_c4"
  iam_role_template_file = "../../artifacts/iam-role-sts-assume.json"
  iam_policy_template_file = "../../artifacts/iam-policy-ec2-describe-instances.json"
}
