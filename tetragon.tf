/*
https://tetragon.io/docs/installation/kubernetes/

helm repo add cilium https://helm.cilium.io
helm repo update
helm install tetragon cilium/tetragon -n kube-system
...


kubectl get ds tetragon -n kube-system
kubectl logs -n kube-system -l app.kubernetes.io/name=tetragon -c export-stdout -f

# */



resource "helm_release" "install-tetragon" {
  depends_on = [ helm_release.install-cillium ]
  name       = "tetragon"
  namespace  = "kube-system"
  chart      = "tetragon"
  repository = "https://helm.cilium.io/"
  force_update = true  
}