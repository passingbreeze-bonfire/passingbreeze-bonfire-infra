## EKS / ArgoCD

resource "helm_release" "argo_cd" {
  namespace        = "argo-cd"
  create_namespace = true

  name       = "argo-cd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "5.50.1"

  values = [
    file("${path.module}/helm_values/argo-cd.yaml")
  ]
}
