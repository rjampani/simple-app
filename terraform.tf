terraform {
    required_providers {
      aws = {
          source = "hashicorp/aws"
      }
    }
}

provider "aws" {
    region = "us-east-1"
    access_key = "XXXXXXXXX"
    secret_key = "XXXXXXXXX"
}
#vpc
resource "aws_vpc" "app_vpc" {
    cidr_block = "172.16.0.0/16"
    tags = {
      "Name" = "app_vpc"
    }
}

#private subnets
resource "aws_subnet" "app_private_subnet_az1" {
  vpc_id = aws_vpc.app_vpc.id
  cidr_block = "172.16.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "Name" = "app_private_subnet_us_east_1a_az"
  }
}
resource "aws_subnet" "app_private_subnet_az2" {
  vpc_id = aws_vpc.app_vpc.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    "Name" = "app_private_subnet_us_east_1b_az"
  }
}
resource "aws_subnet" "app_private_subnet_az3" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = "172.16.2.0/24"
    availability_zone = "us-east-1c"
    tags = {
      "Name" = "app_private_subnet_us_east_1c_az"
    }
}
resource "aws_subnet" "app_private_subnet_az4" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = "172.16.3.0/24"
    availability_zone = "us-east-1d"
    tags = {
      "Name" = "app_private_subnet_us_east_1d_az"
    }
}
#public subnets
resource "aws_subnet" "app_public_subnet_az1" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = "172.16.4.0/24"
    availability_zone = "us-east-1a"
    tags = {
      "Name" = "app_public_subnet_us_east_1a_az"
    }
}
resource "aws_subnet" "app_public_subnet_az2" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = "172.16.5.0/24"
    availability_zone = "us-east-1b"
    tags = {
      "Name" = "app_public_subnet_us_east_1b_az"
    }
}
resource "aws_subnet" "app_public_subnet_az3" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = "172.16.6.0/24"
    availability_zone = "us-east-1c"
    tags = {
      "Name" = "app_public_subnet_us_east_1c_az"
    }
}
resource "aws_subnet" "app_public_subnet_az4" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = "172.16.7.0/24"
    availability_zone = "us-east-1d"
    tags = {
      "Name" = "app_public_subnet_us_east_1d_az"
    }
}
# public route table association for all public nets
resource "aws_route_table_association" "app_rta_app_public_subnet_az1" {
    route_table_id = aws_route_table.app_public_route.id
    subnet_id = aws_subnet.app_public_subnet_az1.id
}
resource "aws_route_table_association" "app_rta_app_public_subnet_az2" {
    route_table_id = aws_route_table.app_public_route.id
    subnet_id = aws_subnet.app_public_subnet_az2.id
}
resource "aws_route_table_association" "app_rta_app_public_subnet_az3" {
    route_table_id = aws_route_table.app_public_route.id
    subnet_id = aws_subnet.app_public_subnet_az3.id
}
resource "aws_route_table_association" "app_rta_app_public_subnet_az4" {
    route_table_id = aws_route_table.app_public_route.id
    subnet_id = aws_subnet.app_public_subnet_az4.id
}

#aws elb security group
resource "aws_security_group" "app_elb_sg" {
    name = "app_elb_security_group"
    vpc_id = aws_vpc.app_vpc.id
    ingress {
        description = "allow http on 80"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    } 
}
#aws elb
resource "aws_elb" "app_elb_az1" {
    name = "app-elb-az1"
    security_groups = [aws_security_group.app_elb_sg.id]
    subnets = [ aws_subnet.app_public_subnet_az1.id, aws_subnet.app_public_subnet_az2.id, aws_subnet.app_public_subnet_az3.id, aws_subnet.app_public_subnet_az4.id ]

    listener {
      lb_port = 80
      lb_protocol = "http"
      instance_port = 8080
      instance_protocol = "http"
    }
    health_check {
      target = "HTTP:8080/"
      interval = 30
      timeout = 5
      healthy_threshold = 3
      unhealthy_threshold = 3
    }
}
#aws launch configuration
resource "aws_launch_configuration" "app_launch_configuration" {
    name_prefix = "app_lc_"
    image_id = "ami-042e8287309f5df03"
    instance_type = "t2.micro"
    security_groups = [ aws_security_group.sg_allow_http_8080.id, aws_security_group.sg_allow_bastion_ssh_22.id ]
    key_name = aws_key_pair.app_key.key_name
    user_data = <<-EOF
        #!/bin/bash
        echo "Hello, World!!!! (v1)" > index.html
        nohup busybox httpd -f -p 8080 &
    EOF
}
#aws auto scaling group (ASG)
resource "aws_autoscaling_group" "app_asg" {
    name = "app_asg"
    launch_configuration = aws_launch_configuration.app_launch_configuration.id
    vpc_zone_identifier = [ aws_subnet.app_private_subnet_az1.id, aws_subnet.app_private_subnet_az2.id, aws_subnet.app_private_subnet_az3.id, aws_subnet.app_private_subnet_az4.id ]
    
    min_size = 2
    max_size = 4
    health_check_type = "ELB"
    load_balancers = [aws_elb.app_elb_az1.name]
    tag {
        key = "Name"
        value = "app_asg_instance"
        propagate_at_launch = true
    }
}
# #create s3 bucket for managin artifacts of simple-app
resource "aws_s3_bucket" "app_s3_bucker" {
    bucket = "simple-app-artifact-store"
    acl = "private" 
    tags = {
        Name = "simple-app-artifact-store"
    } 
}
# key pair creation with provided public key
resource "aws_key_pair" "app_key" {
    key_name = "app_key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0gxMTVEInVJvBoltca56qQjDKeu3s4ZR32Wj7EzsA0IPEfuQQzh+T2pts2BbTDP5/I6qv3O3C5s5w1ONrPOY80lsNEtxIvpa3Cxh7sDhDz6ZX7KzMafa9YrC6sOEVo9ywa+xOQGwUUyPRjZlxpBvSpKtgMTVhKdfNqaMoVaWzrD/YZ1DNZsYFp5nrbdYroDpNTixzPFopI6ciE988qiM1LYJatFHlkmqvtvy3sTr2jAzp5lqVDMqWNnaBBDlGItlMcPDL1qwR9Xj4mqGnnx418JGQQhCHsRbijAq87500pQFTLxkMHgyUY6zzqOXI7OtsOgjquZKngsWSdZiJZcrV9gjyAUQ0+O5Hb6H2NSMxoWZOoycNFPGFSAlsplTKTmBatiiZThr5dj8Ih3jcF/chLaZW4ZdchDIf6Vz6819Ei7ymj9R/dtjMvnOWO1Sj7B2VQn8Vp4f5nZkyoJoh9dZgZBtEDo00gE7kVFKuvPrqDzt6+duZL3Szl+v/u9NleH0= ubuntu"
}
#security group allow http 8080
resource "aws_security_group" "sg_allow_http_8080" {
    name = "app_sg_allow_http_8080"
    vpc_id = aws_vpc.app_vpc.id
    ingress {
        description = "allow http 8080"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
#security group allow sbastion sh 22
resource "aws_security_group" "sg_allow_bastion_ssh_22" {
    name = "sg_allow_bastion_ssh_22"
    vpc_id = aws_vpc.app_vpc.id
    ingress {
        description = "allow bastion ssh 22"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["172.16.4.0/24"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
#bastion/jumpbox 
# internet gateway creation
resource "aws_internet_gateway" "app_inet_gateway" {
    vpc_id = aws_vpc.app_vpc.id
    tags = {
        Name = "app_internet_gateway"
    }
}
# public route table creation
resource "aws_route_table" "app_public_route" {
    vpc_id = aws_vpc.app_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.app_inet_gateway.id
    }
    tags = {
        Name = "app_public_route"
    }
}
# public route table association
resource "aws_route_table_association" "app_route_table_association" {
    route_table_id = aws_route_table.app_public_route.id
    subnet_id = aws_subnet.app_public_subnet.id
}
# public subnet creattion
resource "aws_subnet" "app_public_subnet" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = "172.16.8.0/24"
    availability_zone = "us-east-1e"
    map_public_ip_on_launch = true
    tags = {
        Name = "app_public_subnet"
    }
}
# jumpbox/bastion in public subnet
resource "aws_instance" "jumpbox" {
    ami = "ami-042e8287309f5df03"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.app_public_subnet.id
    key_name = aws_key_pair.app_key.key_name
    vpc_security_group_ids = [aws_security_group.sg_allow_ssh_22.id]
    tags = {
        Name = "jumpbox"
    }
}
#security group allow sbastion sh 22
resource "aws_security_group" "sg_allow_ssh_22" {
    name = "sq_allow_ssh_22"
    vpc_id = aws_vpc.app_vpc.id
    ingress {
        description = "allow ssh 22"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "app_elb_az1_dns_name" {
    value = aws_elb.app_elb_az1.dns_name
}
output "jumpbox_public_ip" {
    value = aws_instance.jumpbox.public_ip
}   