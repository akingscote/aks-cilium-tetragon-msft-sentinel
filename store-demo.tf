/*
This is a hacky and lazy way to deploy an app, all via terraform
https://github.com/Azure-Samples/aks-store-demo?tab=readme-ov-file#run-on-any-kubernetes
*/

resource "kubernetes_namespace" "pets" {
  metadata {
    name = "pets"
  }
#   lifecycle {
#     ignore_changes = [ uid ]
#   }
}

data "http" "aks-all-in-one" {
  url = "https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/main/aks-store-all-in-one.yaml"
  method = "GET"
}

data "kubectl_file_documents" "docs" {
    content = data.http.aks-all-in-one.response_body
}
resource "kubectl_manifest" "aks-all-in-one" {
    depends_on = [ helm_release.install-cillium, helm_release.install-tetragon ]
    for_each  = data.kubectl_file_documents.docs.manifests
    yaml_body=each.value
    override_namespace = kubernetes_namespace.pets.metadata[0].name      
}