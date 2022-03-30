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

resource "aws_security_group" "sg" {
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
    # allow traffic for TCP 22 to host
    ingress {
        description = "Port for SSH access"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # allow traffic for TCP 22 from host
    egress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # allow traffic for all traffic from host
    egress {
        description = "Port for access to Internet"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    depends_on  = [aws_vpc.aws_vpc]
}

resource "aws_subnet" "public_subnet" {
    count                   = "${length(var.availability_zone)}"
    vpc_id 		            = "${aws_vpc.aws_vpc.id}"
    cidr_block              = "${element(var.public_cidr_block, count.index)}"
	availability_zone_id	= "${element(var.availability_zone, count.index)}"

    tags = {
		Name            = "${var.name}-public-subnet-${var.environment}"
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
        Name            = "${var.name}-private-subnet-${var.environment}"
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
