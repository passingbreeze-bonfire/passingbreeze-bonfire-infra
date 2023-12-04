## EKS / Karpenter

locals {
  node_pools = [
    "core", "service"
  ]
}

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name                               = module.eks.cluster_name
  irsa_oidc_provider_arn                     = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts            = ["karpenter:karpenter"]
  irsa_use_name_prefix                       = false
  enable_karpenter_instance_profile_creation = true

  iam_role_additional_policies = {
    AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonSSMFullAccess                = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
    AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  chart      = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  version    = "v0.32.3"

  set {
    name  = "settings.isolatedVPC"
    value = true
  }
  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }
  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter.instance_profile_name
  }
  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter.queue_name
  }
}

resource "kubectl_manifest" "karpenter_node_class_default" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      role: "${module.karpenter.role_name}"
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        app.kubernetes.io/created-by: ${module.eks.cluster_name}
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 50Gi
            volumeType: gp3
            iops: 3000
            deleteOnTermination: true
            throughput: 125
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "node_pools" {
  for_each  = toset(local.node_pools)
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: ${each.key}
    spec:
      template:
        metadata:
          labels:
            type: ${each.key}
        spec:
          requirements:
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: "node.kubernetes.io/instance-type"
              operator: In
              values: ["c6a.large", "m6a.large", "r6a.large"]
          nodeClassRef:
            name: default
      limits:
        cpu: "1000"
        memory: 1000Gi
      disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 720h # 30 * 24h = 720h
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

# test deployment
resource "kubectl_manifest" "karpenter_deployment_default" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: inflate
    spec:
      replicas: 0
      selector:
        matchLabels:
          app: inflate
      template:
        metadata:
          labels:
            app: inflate
        spec:
          nodeSelector:
            type: core
          terminationGracePeriodSeconds: 0
          containers:
            - name: inflate
              image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
              resources:
                requests:
                  memory: 1Gi
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}
