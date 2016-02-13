/* kept here for reference, but use set_aws.sh instead */
/*provider "aws" {
    //access_key = "ACCESS_KEY_HERE"
    //secret_key = "SECRET_KEY_HERE"
    region = "us-west-2"
}*/

variable "machine_name" {}
variable "key_pair_name" {}
variable "instance_type" {}
variable "spot_price" {}
variable "ami" {}

resource "aws_security_group" "cheapdebug" {
	name = "${var.machine_name}"
	description = "allow ssh"
	ingress {
		from_port = 0
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_spot_instance_request" "cheapdebug" {
    ami = "${var.ami}"
    count = 1
    spot_price = "${var.spot_price}"
    instance_type = "${var.instance_type}"
    security_groups = ["${aws_security_group.cheapdebug.name}"]
    wait_for_fulfillment = 1
    key_name = "${var.key_pair_name}"
    user_data = "${file("user_data.sh")}"
}

/* makes sure that the output tfstate has a json entry that jq can parse */
output "sir_ids" {
	value = "${join(" ", aws_spot_instance_request.cheapdebug.*.id)}"
}
