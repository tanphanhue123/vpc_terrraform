terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.45.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
# CREATE VPC
resource "aws_vpc" "vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_hostnames = true
        tags = {
            "Name" = "Custom"
        }   
}
# resource "aws_subnet" "private_subnet_2a" {
#     vpc_id = aws_vpc.vpc.id
#     cidr_block = "10.0.1.0/24"
#     availability_zone = "us-west-2a"   
#         tags = {
#           "Name" = "private_subnet"
#         }
# }
# resource "aws_subnet" "private_subnet_2b" {
#   vpc_id     = aws_vpc.vpc.id
#   cidr_block = "10.0.2.0/24"
#   availability_zone = "us-west-2b"

#   tags = {
#     "Name" = "private-subnet"
#   }
# }

# resource "aws_subnet" "private_subnet_2c" {
#   vpc_id     = aws_vpc.vpc.id
#   cidr_block = "10.0.3.0/24"
#   availability_zone = "us-west-2c"

#   tags = {
#     "Name" = "private-subnet"
#   }
# }

# CREATE SUBNET
# locals {
#   private = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
#   public = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
#   zone = ["us-west-2a","us-west-2b","us-west-2c"]
# }

resource "aws_subnet" "private_subnet" {
    count = length(var.private_subnet)
    vpc_id = "10.0.0.0/16"
    cidr_block = var.private_private[count.index]
    availability_zone = var.availability_zone[count.index % length(var.availability_zone)]
    tags = {
      "name" = "private_subnet"
    }
}

# CREATE PUBLIC SUBNET
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet[count.index]
  availability_zone = var.availability_zone[count.index % length(var.availability_zone)]

  tags = {
    "Name" = "public-subnet"
  }
}

# CREAT INTERNETGW
resource "aws_internet_gateway" "ig" {
    vpc_id = aws_vpc.vpc.id
    tags = {
      "name" = "igw"
    }
  
}

# ATTACH INTERNETGW TO VPC
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0"
    gateway_id = aws_internet_gateway.ig.id
  }
  tags = {
    Name = "public_route"
}
}

# PUBLIC ROUTE TABLE (PUBLIC_SUBNET)
resource "aws_route_table_association" "public_association" {
    for_each = { for k,v in aws_subnet.public_subnet : k => v }
    subnet_id = each.value.id
    route_table_id = aws_route_table.public.id
}

# ALLOCATE EIP
resource "aws_eip" "elastic_ip" {
    vpc = true
  
}

# CREAT NATGW
resource "aws_nat_gateway" "public" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "Public NAT"
    }
}

# CREATE PRIVATE ROUTE TABLE
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.vpc.id

    route {
    cidr_block = "0.0.0.0"
    gateway_id = aws_nat_gateway.public.id
    
  }
  tags = {
    Name = "route_table_private"
    }
}

# CREATE ROUTE TABLE ASSOCIATION (PRIVATE SUBNET)
resource "aws_route_table_association" "public_private" {
    for_each = { for k,v in aws_subnet.private_subnet : k => v }
    subnet_id = each.value.id
    route_table_id = aws_route_table.private.id  
}



