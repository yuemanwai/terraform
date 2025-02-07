provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id             = aws_vpc.main.id
  cidr_block         = "10.0.1.0/24"
  availability_zone  = "us-east-1a"
  tags = {
    Name = "main-subnet-a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id             = aws_vpc.main.id
  cidr_block         = "10.0.2.0/24"
  availability_zone  = "us-east-1b"
  tags = {
    Name = "main-subnet-b"
  }
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}


resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks-demo-cluster"
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.subnet_a.id,
      aws_subnet.subnet_b.id
    ]
  }
}