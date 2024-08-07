### EKS / External DNS
#
#locals {
#  oidc_url       = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
#  aws_account_id = data.aws_caller_identity.current.account_id
#}
#

#}
#
#resource "aws_iam_role_policy" "external_dns" {
#  name = "${module.eks.cluster_name}-external-dns-policy"
#  role = aws_iam_role.external_dns.name
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect = "Allow"
#        Action = [
#          "route53:ChangeResourceRecordSets"
#        ]
#        Resource = [
#          "arn:aws:route53:::hostedzone/*"
#        ]
#      },
#      {
#        Effect = "Allow"
#        Action = [
#          "route53:ListHostedZones",
#          "route53:ListResourceRecordSets"
#        ]
#        Resource = [
#          "*"
#        ]
#      }
#    ]
#  })
#}
#
#resource "kubernetes_service_account" "external_dns" {
#  metadata {
#    name      = "external-dns"
#    namespace = "kube-system"
#    annotations = {
#      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
#    }
#  }
#  automount_service_account_token = true
#}
#
#resource "kubernetes_cluster_role" "external_dns" {
#  metadata {
#    name = "external-dns"
#  }
#
#  rule {
#    api_groups = [""]
#    resources  = ["services", "pods", "nodes", "endpoints"]
#    verbs      = ["get", "list", "watch"]
#  }
#
#  rule {
#    api_groups = ["extensions", "networking.k8s.io", "networking"]
#    resources  = ["ingresses"]
#    verbs      = ["get", "list", "watch"]
#  }
#
#  rule {
#    api_groups = ["networking.istio.io"]
#    resources  = ["gateways"]
#    verbs      = ["get", "list", "watch"]
#  }
#}
#
#resource "kubernetes_cluster_role_binding" "external_dns" {
#  metadata {
#    name = "external-dns"
#  }
#  role_ref {
#    api_group = "rbac.authorization.k8s.io"
#    kind      = "ClusterRole"
#    name      = kubernetes_cluster_role.external_dns.metadata.0.name
#  }
#  subject {
#    kind      = "ServiceAccount"
#    name      = kubernetes_service_account.external_dns.metadata.0.name
#    namespace = kubernetes_service_account.external_dns.metadata.0.namespace
#  }
#}
#
#resource "helm_release" "external-dns" {
#  name       = "external-dns"
#  namespace  = kubernetes_service_account.external_dns.metadata.0.namespace
#  wait       = true
#  repository = "https://kubernetes-sigs.github.io/external-dns/"
#  chart      = "external-dns"
#  version    = "v1.13.1"
#
#  set {
#    name  = "rbac.create"
#    value = false
#  }
#
#  set {
#    name  = "serviceAccount.create"
#    value = false
#  }
#
#  set {
#    name  = "serviceAccount.name"
#    value = kubernetes_service_account.external_dns.metadata.0.name
#  }
#
#  set {
#    name  = "rbac.pspEnabled"
#    value = false
#  }
#
#  set {
#    name  = "name"
#    value = "${module.eks.cluster_name}-external-dns"
#  }
#
#  set {
#    name  = "provider"
#    value = "aws"
#  }
#
#  set {
#    name  = "policy"
#    value = "sync"
#  }
#
#  set {
#    name  = "logLevel"
#    value = "warning"
#  }
#
#  set {
#    name  = "sources"
#    value = "{ingress,service}"
#  }
#
#  set {
#    name  = "aws.region"
#    value = data.aws_region.current.name
#  }
#}
