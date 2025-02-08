#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

# 硬編碼 IAM 角色的 ARN 和名稱
locals {
  lab_role_arn = "arn:aws:iam::123456789012:role/LabRole"
  lab_role_name = "LabRole"
}

# Use existing IAM role
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# EC2 Security Group to allow networking traffic with EKS cluster
resource "aws_security_group" "demo-cluster" {
  name        = "terraform-eks-demo-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.demo.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks-demo"
  }
}

resource "aws_security_group_rule" "demo-cluster-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.demo-cluster.id
  to_port           = 443
  type              = "ingress"
}

# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks-demo-cluster"
  role_arn = local.lab_role_arn

  vpc_config {
    security_group_ids = [aws_security_group.demo-cluster.id]
    subnet_ids         = aws_subnet.public[*].id
  }
}