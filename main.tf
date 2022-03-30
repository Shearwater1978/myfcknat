provider "aws" {
  region = "${var.aws-region}"
  shared_credentials_file = "~/.aws/credentials"
  version = "~> 2.64.0"
}

module "aws_vpc" {
    source                              = "./modules/vpc"
    name                                = "fckNatVPC"
    environment                         = "dev"
    vpc_cidr                            = "10.0.0.0/16"
    public_cidr_block                   = ["10.0.1.0/24"]
    private_cidr_block                  = ["10.0.10.0/24"]
    allowed_ports                       = ["22",]
    availability_zone		        	      = ["use2-az1"]
    enable_internet_gateway	        	  = "true"
}


module "fckNAT" {
    source                              = "./modules/ec2"
    name                                = "fckNAT"
    environment                         = "dev"
    vpc_security_group_ids              = ["${module.aws_vpc.public_security_group_id}"]
    subnet_id                           = "${module.aws_vpc.publicsubnet_id_0}"
    key_path                            = "/root/.ssh/id_rsa.pub"
    home_dir                            = "${var.home_dir}"
}

output "connection-string" {
	value = "ssh -i ~/.ssh/${module.fckNAT.key_pair_name} ec2-user@${element(module.fckNAT.ec2_public_ip,0)}"
}