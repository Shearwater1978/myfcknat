resource "aws_vpc" "aws_vpc" {
    cidr_block                          = "${var.vpc_cidr}"
    instance_tenancy                    = "default"
    enable_dns_support                  = "true"
    enable_dns_hostnames                = "true"
    assign_generated_ipv6_cidr_block    = "false"
    enable_classiclink                  = "false"

    tags = {
      Name = "${var.vpc_name}-${var.environment}"
    }
}

resource "aws_internet_gateway" "default" {
	vpc_id = "${aws_vpc.aws_vpc.id}"

	tags = {
        Name            = "${var.vpc_name}-igw"
        Environment     = "${var.environment}"
        Orchestration   = "${var.orchestration}"
        Createdby       = "${var.createdby}"
    }

	depends_on  = [aws_vpc.aws_vpc]
}

resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.aws_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

    tags = {
        Name            = "${var.vpc_name}PublicRT"
        Environment     = "${var.environment}"
        Orchestration   = "${var.orchestration}"
        Createdby       = "${var.createdby}"
    }

   depends_on  = [aws_internet_gateway.default]

}

resource "aws_route_table" "private_rt" {
  vpc_id = "${aws_vpc.aws_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
    # network_interface_id = ""
  }

    tags = {
        Name            = "${var.vpc_name}PrivateRT"
        Environment     = "${var.environment}"
        Orchestration   = "${var.orchestration}"
        Createdby       = "${var.createdby}"
    }

   depends_on  = [aws_internet_gateway.default]

}

resource "aws_security_group" "sg-public" {
    name                = "${var.name}-sg-public"
    description         = "Security Group ${var.name}-sg-public"
    vpc_id              = "${aws_vpc.aws_vpc.id}"

    tags = {
        Name            = "${var.name}-sg-public"
        Environment     = "${var.environment}"
        Orchestration   = "${var.orchestration}"
        Createdby       = "${var.createdby}"
    }
    lifecycle {
        create_before_destroy = true
    }
    egress {
        description = "Port for access to Internet"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    depends_on  = [aws_vpc.aws_vpc]
}

resource "aws_security_group" "sg-private" {
    name                = "${var.name}-sg-private"
    description         = "Security Group ${var.name}-sg-private"
    vpc_id              = "${aws_vpc.aws_vpc.id}"

    tags = {
        Name            = "${var.name}-sg-private"
        Environment     = "${var.environment}"
        Orchestration   = "${var.orchestration}"
        Createdby       = "${var.createdby}"
    }
    lifecycle {
        create_before_destroy = true
    }

    depends_on  = [aws_security_group.sg-public]
}

resource "aws_security_group_rule" "public_ingress_ports_ssh" {
    type                = "ingress"
    description         = "Provide access from the Internet via SSH"
    security_group_id   = "${aws_security_group.sg-public.id}"
    from_port           = 22
    to_port             = 22
    protocol            = "tcp"
    cidr_blocks         = ["0.0.0.0/0"]

    depends_on  = [aws_security_group.sg-public]
}

resource "aws_security_group_rule" "private_ingress_ports_ssh" {
    type                = "ingress"
    description         = "Provide access from the fckNatSrv via SSH"
    security_group_id   = "${aws_security_group.sg-private.id}"
    source_security_group_id = "${aws_security_group.sg-public.id}"
    from_port           = 22
    to_port             = 22
    protocol            = "tcp"

    depends_on  = [aws_security_group.sg-private]
}

resource "aws_security_group_rule" "ingress_from_private_sg" {
    type                = "ingress"
    description         = "Provide access to the Internet through PublicSG"
    security_group_id   = "${aws_security_group.sg-public.id}"
    source_security_group_id = "${aws_security_group.sg-private.id}"
    from_port           = 0
    to_port             = 0
    protocol            = "-1"

    depends_on  = [aws_security_group.sg-public]
}

resource "aws_security_group_rule" "egress_to_private_sg" {
    type                = "egress"
    description         = "Provide access to the Internet through PublicSG"
    security_group_id   = "${aws_security_group.sg-private.id}"
    source_security_group_id = "${aws_security_group.sg-public.id}"
    from_port           = 0
    to_port             = 0
    protocol            = "-1"

    depends_on  = [aws_security_group.sg-private]
}

resource "aws_subnet" "public_subnet" {
    count                   = "${length(var.availability_zone)}"
    vpc_id 		            = "${aws_vpc.aws_vpc.id}"
    cidr_block              = "${element(var.public_cidr_block, count.index)}"
	availability_zone_id	= "${element(var.availability_zone, count.index)}"

    tags = {
		Name            = "${var.name}-public-subnet"
        Environment     = "${var.environment}"
        Orchestration   = "${var.orchestration}"
        Createdby       = "${var.createdby}"
    }

    depends_on  = [aws_vpc.aws_vpc]
}

resource "aws_subnet" "private_subnet" {
	count                   = "${length(var.availability_zone)}"
    vpc_id                  = "${aws_vpc.aws_vpc.id}"
	cidr_block              = "${element(var.private_cidr_block, count.index)}"
    availability_zone_id    = "${element(var.availability_zone, count.index)}"

    tags = {
        Name            = "${var.name}-private-subnet"
        Environment     = "${var.environment}"
        Orchestration   = "${var.orchestration}"
        Createdby       = "${var.createdby}"
    }

    depends_on  = [aws_vpc.aws_vpc]
}

resource "aws_route_table_association" "a" {
	count = "${length(var.public_cidr_block)}"
	subnet_id      = "${element(aws_subnet.public_subnet.*.id,count.index)}"
	route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_route_table_association" "b" {
	count = "${length(var.private_cidr_block)}"
	subnet_id      = "${element(aws_subnet.private_subnet.*.id,count.index)}"
	route_table_id = "${aws_route_table.private_rt.id}"
}
