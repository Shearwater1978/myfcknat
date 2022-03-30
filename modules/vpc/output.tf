output "instance_tenancy" {
    value = "${aws_vpc.aws_vpc.instance_tenancy}"
}

output "vpc_id" {
    value = "${aws_vpc.aws_vpc.id}"
}

output "vpc_cidr_block" {
  value = "${aws_vpc.aws_vpc.cidr_block}"
}

output "security_group_id" {
    value = "${aws_security_group.sg.id}"
}

output "default_security_group_id" {
    value = "${aws_vpc.aws_vpc.default_security_group_id}"
}

output "public_subnet_id" {
    value = "${aws_subnet.public_subnet.*.id}"
}

output "private_subnet_id" {
    value = "${aws_subnet.private_subnet.*.id}"
}

output "publicsubnet_id_0" {
    value = "${aws_subnet.public_subnet.0.id}"
}
