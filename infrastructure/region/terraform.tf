variable "aws_access_key" { }
variable "global_region" { }
variable "remote_state_bucket" { }
variable "global_tag" { }
variable "global_remote_state_key" { }
variable "region" { }
variable "availability_zones" { type = "list" }
variable "vpc_cidr_block" { }
variable "vpc_subnet_cidrs" { type = "list" }
variable "vpn_cidr_blocks" { type = "list", default = [] }

variable "ec2_instance_vpn" { type = "map" }
variable "ec2_vpn_security_group_rules" { type = "list", default = [] }

variable "ec2_instance_management" { type = "map" }
variable "ec2_management_security_group_rules" { type = "list", default = [] }

variable "ec2_instance_compute" { type = "map" }
variable "ec2_instance_compute_c4" { type = "map" }
variable "ec2_compute_security_group_rules" { type = "list", default = [] }

variable "elb_fabio_security_group_rules" { type = "list", default = [] }

output "infrastructure" { value = "${data.terraform_remote_state.global.infrastructure}" }
output "environment" { value = "${data.terraform_remote_state.global.environment}" }
output "region" { value = "${var.region}" }
output "vpc_id" { value = "${module.aws-vpc.id}" }
output "private_domain" { value = "${data.terraform_remote_state.global.infrastructure}.${var.region}" }
output "vpc_subnet_cidrs" { value = "${var.vpc_subnet_cidrs}" }
output "vpc_subnet_ids" { value = "${module.aws-vpc.subnet_ids}" }

output "ec2_vpn_public_ips" { value = "${module.aws-ec2-vpn.public_ips}" }
output "ec2_vpn_private_ips" { value = "${module.aws-ec2-vpn.private_ips}" }
output "ec2_vpn_security_group_id" { value = "${module.aws-security-group-vpn.id}" }
output "ec2_vpn_host_group_name" { value = "${data.terraform_remote_state.global.host_group_vpn["name"]}" }

output "ec2_management_public_ips" { value = "${module.aws-ec2-management.public_ips}" }
output "ec2_management_private_ips" { value = "${module.aws-ec2-management.private_ips}" }
output "ec2_management_security_group_id" { value = "${module.aws-security-group-management.id}" }
output "ec2_management_host_group_name" { value = "${data.terraform_remote_state.global.host_group_management["name"]}" }

output "ec2_compute_public_ips" { value = "${module.aws-ec2-compute.public_ips}" }
output "ec2_compute_c4_public_ips" { value = "${module.aws-ec2-compute-c4.public_ips}" }
output "ec2_compute_private_ips" { value = "${module.aws-ec2-compute.private_ips}" }
output "ec2_compute_security_group_id" { value = "${module.aws-security-group-compute.id}" }
output "ec2_compute_host_group_name" { value = "${data.terraform_remote_state.global.host_group_compute["name"]}" }
output "ec2_compute_c4_host_group_name" { value = "${data.terraform_remote_state.global.host_group_compute_c4["name"]}" }

output "elb_fabio_dns_name" { value = "${module.aws-elb-fabio.dns_name}" }
output "ec2_ssh_security_group_id" { value = "${module.aws-security-group-ssh.id}" }

provider "aws" {
  access_key = "${var.aws_access_key}"
  region = "${var.region}"
}

resource "aws_key_pair" "terraform" {
  key_name = "${data.terraform_remote_state.global.infrastructure}-${data.terraform_remote_state.global.environment}-${var.region}-terraform"
  public_key = "${data.terraform_remote_state.global.ec2_public_key}"
}

module "aws-vpc" {
  source = "../modules/aws-vpc"
  infrastructure = "${data.terraform_remote_state.global.infrastructure}"
  environment = "${data.terraform_remote_state.global.environment}"
  vpc_cidr_block = "${var.vpc_cidr_block}"
  vpc_subnet_cidrs = "${var.vpc_subnet_cidrs}"
  availability_zones = "${var.availability_zones}"
  private_domain = "${data.terraform_remote_state.global.infrastructure}.${var.region}"
}

module "aws-route53-private" {
  source = "../modules/aws-route53"
  vpc_id = "${module.aws-vpc.id}"
  domain = "${data.terraform_remote_state.global.infrastructure}.${var.region}"
}

module "aws-ec2-vpn" {
  source = "../modules/aws-ec2-vpn"
  infrastructure = "${data.terraform_remote_state.global.infrastructure}"
  environment = "${data.terraform_remote_state.global.environment}"
  region = "${var.region}"
  instance_count = "${var.ec2_instance_vpn["size"]}"
  host_group_name = "${data.terraform_remote_state.global.host_group_vpn["name"]}"
  instance_type = "${var.ec2_instance_vpn["type"]}"
  ami_id = "${var.ec2_instance_vpn["ami"] == "default" ? data.aws_ami.default.id : var.ec2_instance_vpn["ami"]}"
  security_group_ids = ["${module.aws-security-group-vpn.id}","${module.aws-security-group-ssh.id}"]
  user_data = "${data.terraform_remote_state.global.ec2_user_data}"
  key_name = "${var.ec2_instance_vpn["key"] == "default" ? aws_key_pair.terraform.key_name : var.ec2_instance_vpn["key"]}"
  subnet_cidrs = "${var.vpc_subnet_cidrs}"
  subnet_ids = "${module.aws-vpc.subnet_ids}"
  iam_instance_profile = "${data.terraform_remote_state.global.host_group_vpn["iam_instance_profile"]}"
  private_zone_id = "${module.aws-route53-private.zone_id}"
  public_zone_id = "${data.terraform_remote_state.global.public_zone_id}"
}

module "aws-ec2-management" {
  source = "../modules/aws-ec2-management"
  infrastructure = "${data.terraform_remote_state.global.infrastructure}"
  environment = "${data.terraform_remote_state.global.environment}"
  region = "${var.region}"
  instance_count = "${var.ec2_instance_management["size"]}"
  host_group_name = "${data.terraform_remote_state.global.host_group_management["name"]}"
  instance_type = "${var.ec2_instance_management["type"]}"
  security_group_ids = ["${module.aws-security-group-management.id}","${module.aws-security-group-ssh.id}"]
  ami_id = "${var.ec2_instance_management["ami"] == "default" ? data.aws_ami.default.id : var.ec2_instance_management["ami"]}"
  user_data = "${data.terraform_remote_state.global.ec2_user_data}"
  key_name = "${var.ec2_instance_management["key"] == "default" ? aws_key_pair.terraform.key_name : var.ec2_instance_management["key"]}"
  subnet_cidrs = "${var.vpc_subnet_cidrs}"
  subnet_ids = "${module.aws-vpc.subnet_ids}"
  iam_instance_profile = "${data.terraform_remote_state.global.host_group_management["iam_instance_profile"]}"
  private_zone_id = "${module.aws-route53-private.zone_id}"
}

module "aws-ec2-compute" {
  source = "../modules/aws-ec2-compute"
  infrastructure = "${data.terraform_remote_state.global.infrastructure}"
  region = "${var.region}"
  environment = "${data.terraform_remote_state.global.environment}"
  instance_count = "${var.ec2_instance_compute["size"]}"
  host_group_name = "${data.terraform_remote_state.global.host_group_compute["name"]}"
  instance_type = "${var.ec2_instance_compute["type"]}"
  ami_id = "${var.ec2_instance_compute["ami"] == "default" ? data.aws_ami.default.id : var.ec2_instance_compute["ami"]}"
  security_group_ids = ["${module.aws-security-group-compute.id}","${module.aws-security-group-ssh.id}"]
  user_data = "${data.terraform_remote_state.global.ec2_user_data}"
  key_name = "${var.ec2_instance_compute["key"] == "default" ? aws_key_pair.terraform.key_name : var.ec2_instance_compute["key"]}"
  subnet_cidrs = "${var.vpc_subnet_cidrs}"
  subnet_ids = "${module.aws-vpc.subnet_ids}"
  iam_instance_profile = "${data.terraform_remote_state.global.host_group_compute["iam_instance_profile"]}"
  private_zone_id = "${module.aws-route53-private.zone_id}"
}

module "aws-ec2-compute-c4" {
  source = "../modules/aws-ec2-compute"
  infrastructure = "${data.terraform_remote_state.global.infrastructure}"
  region = "${var.region}"
  environment = "${data.terraform_remote_state.global.environment}"
  instance_count = "${var.ec2_instance_compute_c4["size"]}"
  host_group_name = "${data.terraform_remote_state.global.host_group_compute_c4["name"]}"
  instance_type = "${var.ec2_instance_compute_c4["type"]}"
  ami_id = "${var.ec2_instance_compute_c4["ami"] == "default" ? data.aws_ami.default.id : var.ec2_instance_compute_c4["ami"]}"
  security_group_ids = ["${module.aws-security-group-compute.id}","${module.aws-security-group-ssh.id}"]
  user_data = "${data.terraform_remote_state.global.ec2_user_data}"
  key_name = "${var.ec2_instance_compute_c4["key"] == "default" ? aws_key_pair.terraform.key_name : var.ec2_instance_compute_c4["key"]}"
  subnet_cidrs = "${var.vpc_subnet_cidrs}"
  subnet_ids = "${module.aws-vpc.subnet_ids}"
  iam_instance_profile = "${data.terraform_remote_state.global.host_group_compute["iam_instance_profile"]}"
  private_zone_id = "${module.aws-route53-private.zone_id}"
}

module "aws-security-group-vpn" {
  source = "../modules/aws-security-group"
  infrastructure = "${data.terraform_remote_state.global.infrastructure}"
  region = "${var.region}"
  environment = "${data.terraform_remote_state.global.environment}"
  host_group_name = "${data.terraform_remote_state.global.host_group_vpn["name"]}"
  vpc_id = "${module.aws-vpc.id}"
  rules = ["${var.ec2_vpn_security_group_rules}"]
}

module "aws-security-group-management" {
  source = "../modules/aws-security-group"
  infrastructure = "${data.terraform_remote_state.global.infrastructure}"
  region = "${var.region}"
  environment = "${data.terraform_remote_state.global.environment}"
  host_group_name = "${data.terraform_remote_state.global.host_group_management["name"]}"
  vpc_id = "${module.aws-vpc.id}"
  rules = ["${var.ec2_management_security_group_rules}"]
}

module "aws-security-group-compute" {
  source = "../modules/aws-security-group"
  infrastructure = "${data.terraform_remote_state.global.infrastructure}"
  region = "${var.region}"
  environment = "${data.terraform_remote_state.global.environment}"
  host_group_name = "${data.terraform_remote_state.global.host_group_compute["name"]}"
  vpc_id = "${module.aws-vpc.id}"
  rules = ["${var.ec2_compute_security_group_rules}"]
}

module "aws-security-group-ssh" {
  source = "../modules/aws-security-group"
  infrastructure = "${data.terraform_remote_state.global.infrastructure}"
  region = "${var.region}"
  environment = "${data.terraform_remote_state.global.environment}"
  host_group_name = "ssh"
  vpc_id = "${module.aws-vpc.id}"
  rules = []
}

module "aws-security-group-fabio" {
  source = "../modules/aws-security-group"
  infrastructure = "${data.terraform_remote_state.global.infrastructure}"
  region = "${var.region}"
  environment = "${data.terraform_remote_state.global.environment}"
  host_group_name = "fabio"
  vpc_id = "${module.aws-vpc.id}"
  rules = ["${var.elb_fabio_security_group_rules}"]
}

module "aws-elb-fabio" {
  source = "../modules/aws-elb"
  infrastructure = "${data.terraform_remote_state.global.infrastructure}"
  environment = "${data.terraform_remote_state.global.environment}"
  region = "${var.region}"
  host_group_name = "fabio"
  public_zone_id = "${data.terraform_remote_state.global.public_zone_id}"
  subnet_ids = "${module.aws-vpc.subnet_ids}"
  security_group_ids = ["${module.aws-security-group-fabio.id}"]
  instance_ids = "${module.aws-ec2-compute.instance_ids}"
  http_backend_port = "9999"
  http_backend_hc = "HTTP:9998/health"
}

resource "aws_route" "main" {
  count = "${var.ec2_instance_vpn["size"]}"
  route_table_id = "${module.aws-vpc.route_table_id}"
  destination_cidr_block = "${element(var.vpn_cidr_blocks,count.index)}"
  instance_id = "${element(module.aws-ec2-vpn.instance_ids,count.index)}"
}

data "terraform_remote_state" "global" {
  backend = "s3"
  config {
    bucket = "${var.remote_state_bucket}"
    key = "${var.global_tag}/${var.global_remote_state_key}"
    region = "${var.global_region}"
  }
}

data "aws_ami" "default" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  # Canonical
  owners = ["099720109477"]
}
