include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${local.source_base_url}"
}

locals {
  source_base_url = "../../../../../terraform-modules/aws-ecs-service"

  service_name              = "basket-api"
  image_name                = "winshiftq/basket.api:linux-terraform"
  cloudwatch_log_group_name = "/aws/ecs/eshop/basket-api"
  autoscaling_capacity_provider = "on-demand-micro"
}

dependency "ecs" {
  config_path = "../base"

  mock_outputs = {
    mq_connection_uri             = "fake"
    elasticache_replication_group_primary_endpoint_address        = "fake"
  }
}

inputs = {
  service_cpu                   = 128
  service_memory                = 256
  name                          = local.service_name
  container_name                = local.service_name
  image                         = local.image_name
  cloudwatch_log_group_name     = local.cloudwatch_log_group_name
  autoscaling_capacity_provider = local.autoscaling_capacity_provider
  domain                        = include.root.locals.domain
  container_definitions = templatefile("container_definitions.json", {
    container_name            = local.service_name
    container_port            = 80
    image                     = local.image_name
    service_bus_host          = dependency.ecs.outputs.mq_connection_uri
    cloudwatch_log_group_name = local.cloudwatch_log_group_name
    region                    = include.root.locals.aws_region
    connection_string         = format("%s,%s", dependency.ecs.outputs.elasticache_replication_group_primary_endpoint_address, "abortConnect=false")
    subdomains                = include.root.locals.subdomains
    discovery_services        = include.root.locals.discovery_services
  })
}
