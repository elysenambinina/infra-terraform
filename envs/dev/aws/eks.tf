module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = "1.37" # vérifier qu'elle est en « standard support » dans la console EKS

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["${var.admin_ip}/32"]
  cluster_endpoint_private_access      = true

  authentication_mode                      = "API"
  # Accès administrateur explicite : avec « cluster creator », le plan lancé par la CI
  # (rôle en lecture seule) voyait un faux écart sur l'entrée d'accès.
  enable_cluster_creator_admin_permissions = false
  kms_key_administrators                   = [var.admin_principal_arn]
  access_entries = {
    cluster_creator = {
      principal_arn = var.admin_principal_arn
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    eks-pod-identity-agent = {}
    vpc-cni = {
      before_compute       = true
      configuration_values = jsonencode({ enableNetworkPolicy = "true" })
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 5
      desired_size   = 4
    }
  }
}

output "cluster_name" { value = module.eks.cluster_name }
