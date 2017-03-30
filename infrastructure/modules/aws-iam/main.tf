variable "infrastructure" { }
variable "environment" { }

variable "host_group" { type = "map" }

output "iam_instance_profile" { value = "${aws_iam_instance_profile.main.name}" }

resource "aws_iam_role" "main" {
  name = "${var.infrastructure}-${var.environment}-${var.host_group["name"]}"
  path = "/"
  assume_role_policy = "${file(var.host_group["iam_role_template_file"])}"
}

resource "aws_iam_instance_profile" "main" {
  name = "${var.infrastructure}-${var.environment}-${var.host_group["name"]}"
  roles = ["${aws_iam_role.main.name}"]
}

resource "aws_iam_policy" "main" {
  name = "${var.infrastructure}-${var.environment}-${var.host_group["name"]}"
  path = "/"
  policy ="${file(var.host_group["iam_policy_template_file"])}"
}

resource "aws_iam_role_policy_attachment" "main" {
  role = "${aws_iam_role.main.name}"
  policy_arn = "${aws_iam_policy.main.arn}"
}
