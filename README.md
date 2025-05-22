# README
I'm not likely to support this at any point. It's just intended to show how you can integrate all these components together.

Check out the video demonstration [here](https://www.youtube.com/watch?v=23YzfkZqeEY) and supporting blog post at [https://akingscote.co.uk/](https://akingscote.co.uk/posts/2025-05-22-aks-cilium-tetragon-ebpf/)

## Prerequisites
- Microsoft Azure subscription
- opentofu
- cilium cli (optional)
- hubble cli (optional)

You'll need to enable the `KubeProxyConfigurationPreview` feature in your subscription in order to replace KubeProxy, so will need to do that first, likely with the azure cli.
```
az extension add --name aks-preview
az feature register --namespace "Microsoft.ContainerService" --name "KubeProxyConfigurationPreview"
az provider register --namespace Microsoft.ContainerService
```

# Deployment
Just update `config.yaml` and deploy the terraform. It'll take about 30 minutes to deploy.

## Cost
Microsoft Sentinel costs are actually minimal at a small scale. I think this really sets it apart from other cloud SIEMs, such as Google SecOps, which charges ike $20K+ for a yearly commitment. It means I can deploy and learn the tool without having to remortgage. The other cloud SIEM tools just arent accessible.

Microsoft Azure also have a decent [free tier](https://learn.microsoft.com/en-us/azure/aks/free-standard-pricing-tiers) service for AKS.

