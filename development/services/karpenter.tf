## EKS / Karpenter

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  # In v0.32.0/v1beta1, Karpenter now creates the IAM instance profile
  # so we disable the Terraform creation and add the necessary permissions for Karpenter IRSA
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
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "v0.32.1"

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

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      role: ${module.karpenter.role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 20Gi
            volumeType: gp3
            iops: 3000
            deleteOnTermination: true
            throughput: 125
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_default_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c", "m", "r"]
            - key: karpenter.k8s.aws/instance-size
              operator: In
              values: ["large", "xlarge"]
            - key: "karpenter.sh/capacity-type" # Defaults to on-demand
              operator: In
              values: ["spot", "on-demand"]
      limits:
        cpu: 1000
        memory: 1000Gi
      ttlSecondsAfterEmpty: 30
      ttlSecondsUntilExpired: 2592000
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
      labels:
        type: default
      taints:
      - key: type
        value: default
        effect: NoSchedule
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

resource "kubectl_manifest" "karpenter_service_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: service
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c", "m", "r"]
            - key: karpenter.k8s.aws/instance-size
              operator: In
              values: ["large", "xlarge"]
            - key: "karpenter.sh/capacity-type" # Defaults to on-demand
              operator: In
              values: ["spot", "on-demand"]
      limits:
        cpu: 1000
        memory: 1000Gi
      ttlSecondsAfterEmpty: 30
      ttlSecondsUntilExpired: 2592000
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
      labels:
        type: service
      taints:
      - key: type
        value: service
        effect: NoSchedule
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

resource "kubectl_manifest" "karpenter_default_deployment" {
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
            app: inflate_default
        spec:
          terminationGracePeriodSeconds: 0
          containers:
            - name: inflate_default
              image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
              resources:
                requests:
                  cpu: 1
          nodeSelector:
            type: default
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_service_deployment" {
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
            app: inflate_service
        spec:
          terminationGracePeriodSeconds: 0
          containers:
            - name: inflate_default
              image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
              resources:
                requests:
                  cpu: 1
          nodeSelector:
            type: service
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}
