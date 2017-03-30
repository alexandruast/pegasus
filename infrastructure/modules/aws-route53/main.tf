variable "domain" { }
variable "vpc_id" { default = "" }

output "zone_id" { value = "${aws_route53_zone.main.zone_id}" }
output "name_servers" { value = "${aws_route53_zone.main.name_servers}" }

resource "aws_route53_zone" "main" {
  name = "${var.domain}"
  vpc_id = "${var.vpc_id}"
  comment = "Hosted zone for ${var.domain} - Managed by Terraform"

  lifecycle {
    prevent_destroy = false
  }
}
