provider "aws" {
  region = "us-west-1"  # Specify your desired region
}

# Creating IAM role for EKS
resource "aws_iam_role" "master" {
  name = "vijay-eks-master"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role" "worker" {
  name = "vijay-eks-worker"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "autoscaler" {
  name = "vijay-eks-autoscaler-policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeTags",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.worker.name
}

resource "aws_iam_instance_profile" "worker" {
  depends_on = [aws_iam_role.worker]
  name       = "vijay-eks-worker-new-profile"
  role       = aws_iam_role.worker.name
}
 
# Data source for the existing VPC
data "aws_vpc" "main" {
  tags = {
    Name = "Jumphost-or-main-vpc"  # Specify the name of your existing VPC
  }
}

# Data source for existing subnets
# data "aws_subnet" "subnet-1" {
#   vpc_id = data.aws_vpc.main.id
#   filter {
#     name   = "tag:Name"
#     values = ["MyPublicSubnet01"]
#   }
# }

# data "aws_subnet" "subnet-2" {
#   vpc_id = data.aws_vpc.main.id
#   filter {
#     name   = "tag:Name"
#     values = ["MyPublicSubnet02"]
#   }
# }


resource "aws_subnet" "subnet-1" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "MyPublicSubnet01"
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "MyPublicSubnet02"
  }
}

# Define the security group
resource "aws_security_group" "eks_security_group" {
  vpc_id      = data.aws_vpc.main.id
  description = "Allowing Jenkins, Sonarqube, SSH Access"

  ingress = [
    for port in [22, 8080, 9000, 9090, 80] : {
      description      = "TLS from VPC"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      ipv6_cidr_blocks = ["::/0"]
      self             = false
      prefix_list_ids  = []
      security_groups  = []
      cidr_blocks      = ["0.0.0.0/0"]
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-project-vijay"
  }
}


# Data source for the existing security group
# data "aws_security_group" "eks_sg" {
#   vpc_id = data.aws_vpc.main.id
#   filter {
#     name = "tag:Name"
#     values = ["devops-project-vijay"]
#   }
# }

# Creating EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "project-eks"
  role_arn = aws_iam_role.master.arn

  vpc_config {
    vpc_id = data.aws_vpc.main.id
    subnet_ids         = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
    security_group_ids = [aws_security_group.eks_security_group.id]
  }

  tags = {
    "Name" = "MyEKS"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "project-node-group"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids      = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
  capacity_type   = "ON_DEMAND"
  disk_size       = 20
  instance_types  = ["t2.large"]

  remote_access {
    ec2_ssh_key               = "provisioner"
    source_security_group_ids = [aws_security_group.eks_security_group.id]
  }

  labels = {
    env = "dev"
  }

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}
