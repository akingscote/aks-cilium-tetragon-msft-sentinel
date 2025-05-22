/*
https://docs.cilium.io/en/stable/installation/k8s-install-helm/

> On AKS, Cilium can be installed either manually by administrators via Bring your own CNI or automatically by AKS via Azure CNI Powered by Cilium. Bring your own CNI offers more flexibility and customization as administrators have full control over the installation, but it does not integrate natively with the Azure network stack and administrators need to handle Cilium upgrades. Azure CNI Powered by Cilium integrates natively with the Azure network stack and upgrades are handled by AKS, but it does not offer as much flexibility and customization as it is controlled by AKS. The following instructions assume Bring your own CNI. For Azure CNI Powered by Cilium, see the external installer guide Installation using Azure CNI Powered by Cilium in AKS for dedicated instructions.

https://docs.cilium.io/en/stable/observability/hubble/setup/#setting-up-hubble-observability
# */

resource "helm_release" "install-cillium" {
  depends_on = [
    azapi_update_resource.kube_proxy_disabled, # wait for kube-proxy to be disabled
    azurerm_kubernetes_cluster_node_pool.user # not required, but its nice to install in order
  ]
  name       = "cilium"
  namespace  = "kube-system"
  chart      = "cilium"
  repository = "https://helm.cilium.io/"
  force_update = true

  set {
    name = "kubeProxyReplacement"
    value = true
  }

  set {
    name = "k8sServiceHost"
    value = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host
  }

  set {
    name = "k8sServicePort"
    value = 443
  }

  set {
    name = "nodeinit.enabled"
    value = true
  }

  set {
    name  = "aksbyocni.enabled"
    value = true
  }

  set {
    name  = "hubble.relay.enabled"
    value = true
  }

  set {
    name  = "hubble.ui.enabled"
    value = true
  }

  set {
    name  = "hubble.redact.enabled" // enables redacting sensitive information present in Layer 7 flows
    value = false # disabling for now, so I can see what stuff looks like. This blocks header values
  }

  set {
    name  = "envoy.enabled" // enable envoy for proxy injection, for L7 inspection https://docs.cilium.io/en/stable/security/network/proxy/#proxy-injection
    value = true
  }

 # https://docs.cilium.io/en/stable/network/servicemesh/ingress/
#  https://docs.cilium.io/en/stable/network/servicemesh/l7-traffic-management/
  set {
    name  = "ingressController.enabled" // required for l7
    value = true
  }

  set {
    name  = "ingressController.loadbalancerMode" // required for l7
    value = "dedicated"
  }

    set {
    name  = "ingressController.default" // required for l7
    value = true
  }

    set {
    name  = "envoyConfig.enabled" // required for l7
    value = true
  }

  set {
    name = "loadBalancer.l7.backend"
    value = "envoy"
  }

////////// Optional, enable metrics  /////////////
// https://docs.cilium.io/en/latest/observability/grafana/#deploy-cilium-and-hubble-with-metrics-enabled
  set {
    name = "prometheus.enabled"
    value = true
  }

  set {
    name = "operator.prometheus.enabled"
    value = true
  }

  set {
    name = "prometheus.enabled"
    value = true
  }

  set {
    name = "hubble.metrics.enableOpenMetrics"
    value = true
  }

  set {
    name = "hubble.metrics.enabled"
    value = "{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\\,source_namespace\\,source_workload\\,destination_ip\\,destination_namespace\\,destination_workload\\,traffic_direction}"
  }

////////// Optional, run on system node /////////////
  set {
    name  = "hubble.relay.tolerations[0].key"
    value = "CriticalAddonsOnly"
  }

  set {
    name  = "hubble.relay.tolerations[0].operator"
    value = "Exists"
  }

  set {
    name  = "hubble.relay.tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "hubble.ui.tolerations[0].key"
    value = "CriticalAddonsOnly"
  }

  set {
    name  = "hubble.ui.tolerations[0].operator"
    value = "Exists"
  }

  set {
    name  = "hubble.ui.tolerations[0].effect"
    value = "NoSchedule"
  }
  
}