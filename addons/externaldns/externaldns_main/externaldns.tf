resource "helm_release" "external_dns" {
  depends_on = [module.irsa_externaldns]
  name       = "external-dns"

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "default"

  set = [
    {
      name  = "image.repository"
      value = "registry.k8s.io/external-dns/external-dns"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "external-dns"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.irsa_externaldns.iam_role_arn
    },
    {
      name  = "provider"
      value = "aws"
    },
    {
      name  = "policy"
      value = "sync"
    },
    {
      name  = "domainFilters[0]"
      value = "kriolu-kloud.cv"
    },
  ]
}
