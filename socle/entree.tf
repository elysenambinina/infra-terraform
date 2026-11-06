# Adresse IP publique fixe du point d'entrée des applications.
# Elle reste dans le socle pour survivre à la destruction du cluster : le nom DuckDNS pointe toujours vers elle.
import {
  to = aws_eip.entree
  id = "eipalloc-0982f0e75cae185e1"   # bloc à retirer une fois l'import fait
}

resource "aws_eip" "entree" {
  domain = "vpc"
  tags   = { Name = "gitops-dev-entree" }
}

output "entree_ip"            { value = aws_eip.entree.public_ip }
output "entree_allocation_id" { value = aws_eip.entree.allocation_id }
