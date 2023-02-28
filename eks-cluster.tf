# EKS Cluster private 으로  api 만 제공하도록 한다.
resource "aws_eks_cluster" "this" {
  name     = "${var.project}-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = var.eks_ver

  vpc_config {
    ## security_group_ids      = [aws_security_group.eks_cluster.id, aws_security_group.eks_nodes.id] # already applied to subnet
    subnet_ids              = flatten([aws_subnet.public[*].id, aws_subnet.private[*].id])
    #subnet_ids              = flatten([aws_subnet.private[*].id])
    # 보안으로 public_access 가 true 일 경우 , 외부에서 접속가능. false 일 경우는 vpn 으로 접속가능 , 외부에서 k8s 접속안됨, 서비스는 proxy 
    #kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8001:443 --address 0.0.0.0 식으로 접속 가능하다.
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["${var.cluster_cidr}"]
  }

  tags = merge(
    var.tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]
}


# EKS Node IAM Role
# 정책의 기본 json 파일 생성시  "Version": "2012-10-17" 로 설정한다.
# 콘솔창에서 IAM > Policies > create policy  에서 ,json tab 를 선택한다.
resource "aws_iam_role" "cluster" {
  name = "${var.project}-Cluster-Role"

  assume_role_policy = <<POLICY
{
   "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": [
            "eks.amazonaws.com"
            ]
        },
        "Action": [
               "ec2:*",
               "eks:*",
               "elasticloadbalancing:*",
               "autoscaling:*",
               "cloudwatch:*",
               "logs:*",
               "kms:DescribeKey",
               "iam:AddRoleToInstanceProfile",
               "iam:AttachRolePolicy",
               "iam:CreateInstanceProfile",
               "iam:CreateRole",
               "iam:CreateServiceLinkedRole",
               "iam:GetRole",
               "iam:ListAttachedRolePolicies",
               "iam:ListRolePolicies",
               "iam:ListRoles",
               "iam:PassRole",
               "iam:DetachRolePolicy",
               "iam:ListInstanceProfilesForRole",
               "iam:DeleteRole"
           ],
      }
    ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}


resource "aws_iam_role_policy_attachment" "cluster_tfWS" {
  policy_arn = "arn:aws:iam::585180838533:policy/tfWS"
  role       = aws_iam_role.cluster.name
}



# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project}-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project}-cluster-sg"
  }
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "egress"
}

#fargate policy 정책
resource "aws_iam_role" "eks-fargate-profile" {
  name = "eks-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-fargate-profile" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks-fargate-profile.name
}

resource "aws_eks_fargate_profile" "kube-system" {
  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.

  subnet_ids              = flatten([aws_subnet.private[*].id])
  #subnet_ids = [
  #  aws_subnet.private-us-east-1a.id,
  #  aws_subnet.private-us-east-1b.id
  #]

  selector {
    namespace = "kube-system"
  }
}
