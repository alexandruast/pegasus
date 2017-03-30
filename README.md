cd ./infrastructure

Adjust:
  environments/dev/00-global/terraform.tfvars
  environments/dev/us-east-1/terraform.tfvars

export AWS_SECRET_ACCESS_KEY=<your_access_key_here>

Optional: create a mlab.com mongodb account for pritunl
  export MONGODB_URI_VPN=mongodb://pritunl:<your_password_here>@ds131139.mlab.com:31139/pritunl

Create
./wrapper.sh -env=dev -scope=global apply
./wrapper.sh -env=dev -scope=us-east-1 apply

Provision
./provision.sh -env=dev -region=us-east-1 vpn
./provision.sh -env=dev -region=us-east-1 management
./provision.sh -env=dev -region=us-east-1 compute

Destroy
./wrapper.sh -env=dev -scope=us-east-1 destroy
./wrapper.sh -env=dev -scope=global destroy
