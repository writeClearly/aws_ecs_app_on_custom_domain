# aws_ecs_app_on_custom_domain

## What does it do?
Deploys application from ECR registry, configures load balancing and exposes config to outside world with redirection HTTP -> HTTPS

## Features
- Configurable containers resources in the Fargate
- Application load balancer between two availability zones
- Binding custom domain to the load balancer
- Enabled SSL with termination on load balancer
- Invisible upgrading HTTP request to HTTPS
- Remote .tfstate in AWS s3

## Prerequirements
- terraform >= 0.12
- aws-cli with configured credentials
- configured hosted zone in route53
- your web-app image in ECR with exposed 80
- ssl certificate signed by Amazon covering your desired domain


## Tips:
1. At the time of writing terraform doesn't support input variables in backend, thus to init terraform you need to edit ```backend.tfvars``` <br> with your s3 bucket configuration and then run
```terraform init --backend-config=backend.tfvars```
2. Any variable from ```aws_variables.tf``` may be overwritten by creating ```terraform.tfvars``` <br>
For example if you wish to set region to the Asia
```
#terraform.tfvars
region = {"cheapest" : "ap-southeast-1"}
```

3. You need to specify all attributes when overriding variables from ```aws_variables.tfvars``` in ```terraform.tfvars``` <br> Otherwise you'll run into ```"The given key does not identify an element in this collection value."```

```
#terraform.tfvars
ecs_route53_record = { 
        "zone_id" : "i4k1agpo2"
        # "name"   : "YOU_DID_NOT_SPECIFY"
        }
        
#######
# $ terraform apply
# ERROR The given key "name" does not identify an element in this collection value.
```
