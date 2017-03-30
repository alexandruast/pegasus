variable "aws_access_key" { }
variable "global_region" { }
variable "infrastructure" { }
variable "environment" { }
variable "domain" { }
variable "remote_state_bucket" { }

variable "ec2_public_key" { }
variable "ec2_user_data" { }

variable "host_group_vpn" { type = "map" }
variable "host_group_management" { type = "map" }
variable "host_group_compute" { type = "map" }
variable "host_group_compute_c4" { type = "map" }

output "infrastructure" { value = "${var.infrastructure}" }
output "environment" { value = "${var.environment}" }

output "domain" { value = "${var.domain}" }
output "public_zone_id" { value = "${module.aws-route53-public.zone_id}" }
output "name_servers" { value = "${module.aws-route53-public.name_servers}" }

output "ec2_public_key" { value = "${var.ec2_public_key}" }
output "ec2_user_data" { value = "${var.ec2_user_data}" }

output "host_group_vpn" { value = {
      name = "${var.host_group_vpn["name"]}"
      iam_role_template_file = "${var.host_group_vpn["iam_role_template_file"]}"
      iam_policy_template_file = "${var.host_group_vpn["iam_policy_template_file"]}"
      iam_instance_profile = "${module.aws-iam-vpn.iam_instance_profile}"
}}

output "host_group_management" { value = {
      name = "${var.host_group_management["name"]}"
      iam_role_template_file = "${var.host_group_management["iam_role_template_file"]}"
      iam_policy_template_file = "${var.host_group_management["iam_policy_template_file"]}"
      iam_instance_profile = "${module.aws-iam-management.iam_instance_profile}"
}}

output "host_group_compute" { value = {
      name = "${var.host_group_compute["name"]}"
      iam_role_template_file = "${var.host_group_compute["iam_role_template_file"]}"
      iam_policy_template_file = "${var.host_group_compute["iam_policy_template_file"]}"
      iam_instance_profile = "${module.aws-iam-compute.iam_instance_profile}"
}}

output "host_group_compute_c4" { value = {
      name = "${var.host_group_compute_c4["name"]}"
      iam_role_template_file = "${var.host_group_compute_c4["iam_role_template_file"]}"
      iam_policy_template_file = "${var.host_group_compute_c4["iam_policy_template_file"]}"
      iam_instance_profile = "${module.aws-iam-compute.iam_instance_profile}"
}}

provider "aws" {
  access_key = "${var.aws_access_key}"
  region = "${var.global_region}"
}

module "aws-route53-public" {
  source = "../modules/aws-route53"
  domain = "${var.domain}"
}

module "aws-iam-vpn" {
  source = "../modules/aws-iam"
  infrastructure = "${var.infrastructure}"
  environment = "${var.environment}"
  host_group = "${var.host_group_vpn}"
}

module "aws-iam-management" {
  source = "../modules/aws-iam"
  infrastructure = "${var.infrastructure}"
  environment = "${var.environment}"
  host_group = "${var.host_group_management}"
}

module "aws-iam-compute" {
  source = "../modules/aws-iam"
  infrastructure = "${var.infrastructure}"
  environment = "${var.environment}"
  host_group = "${var.host_group_compute}"
}
