resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # tags = tomap({
  #   "Name"                                      = "main",
  #   "kubernetes.io/cluster/${var.cluster_name}" = "shared",
  # })
  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

resource "aws_subnet" "public" {
  count = 2

  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.demo.id

  tags = tomap({
    "Name"                                      = "terraform-eks-demo-public-${count.index}",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
  })
}

resource "aws_subnet" "private" {
  count = 2

  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  cidr_block        = "10.0.${count.index + 2}.0/24"
  vpc_id            = aws_vpc.demo.id

  tags = tomap({
    "Name"                                      = "terraform-eks-demo-private-${count.index}",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
    "kubernetes.io/role/internal-elb"           = "1"
  })
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }

  tags = {
    Name = "terraform-eks-demo-public"
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "demo" {
  count = 2

  allocation_id = aws_eip.demo[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "terraform-eks-demo-nat-${count.index}"
  }
}

resource "aws_eip" "demo" {
  count = 2

  domain = "vpc"

  tags = {
    Name = "terraform-eks-demo-eip-${count.index}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo[0].id
  }

  tags = {
    Name = "terraform-eks-demo-private"
  }
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}