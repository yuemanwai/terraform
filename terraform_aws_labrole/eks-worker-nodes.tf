#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
#

# resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = data.aws_iam_role.lab_role.name
# }

# resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKSClusterPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = data.aws_iam_role.lab_role.name
# }

# resource "aws_iam_role_policy_attachment" "demo-node-AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = data.aws_iam_role.lab_role.name
# }

resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "demo"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  # depends_on = [
  #   aws_iam_role_policy_attachment.demo-node-AmazonEKSWorkerNodePolicy,
  #   aws_iam_role_policy_attachment.demo-node-AmazonEKSClusterPolicy,
  #   aws_iam_role_policy_attachment.demo-node-AmazonEC2ContainerRegistryReadOnly,
  # ]
}