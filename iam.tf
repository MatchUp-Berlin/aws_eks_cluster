
### Creation of IAM Role for Cluster ###

resource "aws_iam_role" "eks-cluster" {
  name = "eks_cluster_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [ "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
                          "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
                          "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
                          "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess",
                          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/ecr-access"]

  tags = {
    Terraform   = "true"
    Environment = var.AWS_ENVIRONMENT
  }
}

### ECR Access Policy

resource "aws_iam_policy" "ecr-access" {
  name        = "ecr-access"
  path        = "/"
  description = "allows access to ecr for eks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


### Creation of IAM Role for Cluster ###

resource "aws_iam_role" "ecr-manager" {
  name = "ecr_manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "ecr-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ecr:CompleteLayerUpload",
                      "ecr:GetAuthorizationToken",
                      "ecr:UploadLayerPart",
                      "ecr:InitiateLayerUpload",
                      "ecr:BatchCheckLayerAvailability",
                      "ecr:PutImage"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  tags = {
    Terraform   = "true"
    Environment = var.AWS_ENVIRONMENT
  }
}

### load balancer controller IAM Role for Service Account ###

module "load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Terraform   = "true"
    Environment = var.AWS_ENVIRONMENT
  }
}