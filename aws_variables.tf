variable "backend" {
    #!!!!!!!!!!!!!!
    # Backend variables aren't supported yet by terraform
    # You'll need to create the backend.tfvars and initialise terraform using it's config eg:
    # ---------
    # backend.tfvars
    #
    # bucket   = "BUCKET_NAME"
    # key      = "BUCKET/PATH/WHERE/YOU/WISH/TO/STORE/YOUR/terraform.tf"
    # region   = "s3_BUCKET_REGION"
    # ---------
    # $ terraform init -backend-config=backend.tfvars
    #!!!!!!!!!!!!!!
    description     = "Backend for remotely storing terraform state - which resources are currently deployed, backend is necesarry for colaborating on shared terraform"
    type            = map
    default         = {
        "bucket_name"   = "BUCKET_NAME"
        "key"           = "BUCKET/PATH/WHERE/YOU/WISH/TO/STORE/YOUR/terraform.tf"
        "region"        = "s3_BUCKET_REGION"
    }
}

variable "region" {
    description = "Main provider region where you are deploying resources"
    type        = map
    default     = {
        "cheapest" = "us-west-1"
    }
}

#sample string variable - shorter than map, but less readable in main.tf 
variable "ecs_cluster" {
    description = "Elastic Container Service cluster's name"
    type        = string
    default     = "YOUR_CLUSTER_NAME"
}

variable "ecs_app_task_definition" {
    description = "Config for main app in ECS"
    type        = map
    default     = {
        "family"                = "NAME_GIVEN_FOR_ECS_TASK",
        "task_role_arn"         = "IF_YOUR_RUNNING_APP_NEED_AN_ACCESS_TO_ANY_AWS_RESOURCE_CREATE_ROLE_IN_IAM_AND_PASTE_ROLE_ARN_HERE",
        "execution_role_arn"    = "TASK_EXECUTION_ROLE_NEEDED_FOR_ECS_ACTIONS_FOR_EXAMPLE_PULLING_ECR_IMAGES",
        "cpu"                   = "256", # How many VCPU for given task
        "memory"                = "512", # Mb of memory
    }
}

variable "app_alb" {
    description = "Application Load Balancer - distributes traffic between containers"
    type        = map
    default     = {
        "name"  = "YOUR-ALB-NAME-HERE"
    }
}
variable "alb_lb_target_group_HTTP" {
    description = "Application's Load Balancer Target Group - describes what kind of resource is going to receive traffic by specifed protocol"
    type        = map
    default     = {
        "name"  = "YOUR-TARGET-GROUP-NAME"
    }
}
variable "alb_lb_listener_HTTPS" {
    description = "Configuration for redirecting HTTP traffic to HTTPS"
    type        = map
    default     = {
        "ssl_arn"  = "YOUR_SSL_CERTIFICATE_ARN_GOES_HERE"
    }
}
variable "ecs_route53_record" {
    description = "Subdomain Alias for Load Balancer"
    type        = map
    default     = {
        "zone_id"   = "HOSTED_ZONE_ID",
        "name"      = "YOUR_SUBDOMAIN_COVERED_BY_SSL_CERTIFICATE_IN_CERTIFICATE_MANAGER" #eg. my.example.com
    }
}
variable "ecs_app_service" {
    description             = "ECS service definition"
    type                    = map
    default                 = {
        "name"              = "Your_SERVICE_IS_NAMED_HERE"
        "desired_count"     = 2
    }   
}
variable "ecs_app_container_definition" {
    description = "Main app config"
    type        = map
    default     = {
        "name"              = "YOUR-APP-CONTAINER-NAME"
        "container_port"    = "80"  # port exposed by docker container
        "image"             = "XXXX.amazonaws.com/Your-App-name:1.0.0" # image tag from ECR registry
    }
}