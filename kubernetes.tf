data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

### Kubernetes authentication and connection for Helm Provider ###

provider "helm" {
  kubernetes {
    config_path            = "~/.kube/config"
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

### Prometheus Helm Chart ###

resource "helm_release" "prometheus" {
  name       = "prometheus"
  chart      = "prometheus-community/prometheus"
  version    = "15.16.1"
}

### Grafana Helm Chart ###

resource "helm_release" "grafana" {
  name       = "grafana"
  chart      = "grafana/grafana"
  version    = "6.42.2"

  set {
    name  = "adminUser"
    value = var.GRAFANA_ADMIN
  }

  set {
    name  = "adminPassword"
    value = var.GRAFANA_PASSWORD
  }
}

### K8 Load Balancer Controller Helm Chart ###

resource "helm_release" "AWS_Load_Balancer_Controller" {
  name       = "aws-load-balancer-controller"
  chart      = "eks/aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.CLUSTER_NAME
  }

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}

### Kubernetes authentication and connection for K8 Provider ###

provider "kubernetes" {
    config_path            = "~/.kube/config"
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
}

### Load Balancer Service Deployment ###

resource "kubernetes_service" "grafana-lb" {
  metadata {
    name = "grafana-lb"
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "grafana"
    }
    port {
      port        = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}

