include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${local.source_base_url}"
}

locals {
  source_base_url = "../../../../../terraform-modules/aws-ecs-service"

  name                          = "webspa"
  image_name                    = "winshiftq/webspa:linux-terraform"
  cloudwatch_log_group_name     = "/aws/ecs/eshop/webspa"
  route_key                     = "ANY /site/{proxy+}"
  autoscaling_capacity_provider = "on-demand-micro"
}

inputs = {
  name                          = local.name
  container_name                = local.name
  service_cpu                   = 128
  service_memory                = 256
  create_distribution           = false
  route_key                     = local.route_key
  autoscaling_capacity_provider = local.autoscaling_capacity_provider
  cloudwatch_log_group_name     = local.cloudwatch_log_group_name
  domain                        = include.root.locals.domain
  container_definitions = templatefile("container_definitions.json", {
    container_name            = local.name
    container_port            = 80
    image                     = local.image_name
    region                    = include.root.locals.aws_region
    cloudwatch_log_group_name = local.cloudwatch_log_group_name
    subdomains                = include.root.locals.subdomains
  })
}
