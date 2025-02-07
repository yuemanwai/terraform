provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "main-subnet"
  }
}

resource "aws_iam_role" "lab_role" {
  name = "LabRole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "apigateway.amazonaws.com",
          "application-autoscaling.amazonaws.com",
          "athena.amazonaws.com",
          "autoscaling.amazonaws.com",
          "batch.amazonaws.com",
          "backup.amazonaws.com",
          "cloud9.amazonaws.com",
          "cloudformation.amazonaws.com",
          "cloudtrail.amazonaws.com",
          "codecommit.amazonaws.com",
          "codedeploy.amazonaws.com",
          "codewhisperer.amazonaws.com",
          "cognito-idp.amazonaws.com",
          "credentials.iot.amazonaws.com",
          "databrew.amazonaws.com",
          "deepracer.amazonaws.com",
          "dynamodb.amazonaws.com",
          "ec2.amazonaws.com",
          "ec2.application-autoscaling.amazonaws.com",
          "ecs.amazonaws.com",
          "ecs-tasks.amazonaws.com",
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com",
          "elasticbeanstalk.amazonaws.com",
          "elasticfilesystem.amazonaws.com",
          "elasticloadbalancing.amazonaws.com",
          "elasticmapreduce.amazonaws.com",
          "events.amazonaws.com",
          "firehose.amazonaws.com",
          "forecast.amazonaws.com",
          "glue.amazonaws.com",
          "iot.amazonaws.com",
          "iotanalytics.amazonaws.com",
          "iotevents.amazonaws.com",
          "kinesis.amazonaws.com",
          "kinesisanalytics.amazonaws.com",
          "kms.amazonaws.com",
          "lambda.amazonaws.com",
          "logs.amazonaws.com",
          "pipes.amazonaws.com",
          "rds.amazonaws.com",
          "redshift.amazonaws.com",
          "rekognition.amazonaws.com",
          "resource-groups.amazonaws.com",
          "s3.amazonaws.com",
          "sagemaker.amazonaws.com",
          "scheduler.amazonaws.com",
          "secretsmanager.amazonaws.com",
          "servicecatalog.amazonaws.com",
          "sns.amazonaws.com",
          "sqs.amazonaws.com",
          "ssm.amazonaws.com",
          "states.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lab_role_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  role       = aws_iam_role.lab_role.name
  policy_arn = each.value
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks-demo-cluster"
  role_arn = aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.subnet.id]
  }
}