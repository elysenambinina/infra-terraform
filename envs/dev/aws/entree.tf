# Point d'entrée public des applications : une adresse IP fixe (DuckDNS ne gère que des enregistrements A)
# et un rôle pour AWS Load Balancer Controller, qui crée le NLB à partir du Service de Traefik.
resource "aws_eip" "entree" {
  domain = "vpc"
  tags   = { Name = "${local.name}-entree" }
}

module "lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name                            = "aws-load-balancer-controller"
  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

output "entree_ip"            { value = aws_eip.entree.public_ip }
output "entree_allocation_id" { value = aws_eip.entree.allocation_id }
output "entree_subnet_id"     { value = module.vpc.public_subnets[0] }
output "vpc_id"               { value = module.vpc.vpc_id }
