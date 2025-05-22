# README
I'm not likely to support this at any point. It's just intended to show how you can integrate all these components together.

Check out the video demonstration [here](https://www.youtube.com/watch?v=23YzfkZqeEY) and supporting blog post at https://akingscote.co.uk/

## Prerequisites
- Microsoft Azure subscription
- opentofu
- cilium cli
- hubble cli

Update `config.yaml` and deploy the terraform. It'll take about 30 minutes to deploy.

## Cost
Microsoft Sentinel costs are actually minimal at a small scale. I think this really sets it apart from other cloud SIEMs, such as Google SecOps, which charges ike $20K+ for a yearly commitment. It means I can deploy and learn the tool without having to remortgage. The other cloud SIEM tools just arent accessible.

Microsoft Azure also have a decent [free tier](https://learn.microsoft.com/en-us/azure/aks/free-standard-pricing-tiers) service for AKS.

