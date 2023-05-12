include "root" {
  path = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${local.source_base_url}"
}

locals {
  source_base_url = "../../../../../terraform-modules/aws-ecs-service"

  service_name = "basket-api"
  image_name = "winshiftq/basket.api:linux-terraform"
  cloudwatch_log_group_name = "/aws/ecs/eshop/basket-api"
}

dependency "ecs" {
  config_path = "../base"

  mock_outputs = {
    cluster_id = "fake-cluster_id"
    vpc_id = "fake-vpc_id"
    public_subnets = ["fake-public_subnet"]
    lb_id = "arn:aws:elasticloadbalancing:ap-southeast-2:123456789012:fake"
    aws_cloudwatch_log_group_name = "fake-aws_cloudwatch_log_group_name"
    alb_sg_security_group_id = "fake"
    mq_connection_uri = "fake"
    db_connection_string = "fake"
  }
}

dependency "webspa" {
  config_path = "../webspa"

  mock_outputs = {
    lb_dns_name = "fake"
  }
}

inputs = {
  name = local.service_name
  container_name = local.service_name
  image = local.image_name
  cluster_id = dependency.ecs.outputs.cluster_id
  vpc_id = dependency.ecs.outputs.vpc_id
  public_subnets = dependency.ecs.outputs.public_subnets
  lb_id = dependency.ecs.outputs.lb_id
  aws_cloudwatch_log_group_name = dependency.ecs.outputs.aws_cloudwatch_log_group_name
  alb_sg_security_group_id = dependency.ecs.outputs.alb_sg_security_group_id
  service_cpu = 256
  service_memory = 512
  container_definitions = templatefile("container_definitions.json", {
    container_name = local.service_name
    container_port = 80
    image = local.image_name
    service_bus_host = dependency.ecs.outputs.mq_connection_uri
    cloudwatch_log_group_name = local.cloudwatch_log_group_name
    region = include.root.locals.aws_region
    connection_string = format("%s;%s", dependency.ecs.outputs.db_connection_string, "redis-basketdata")
    identity_url = dependency.webspa.outputs.lb_dns_name
    identity_ext_url = dependency.webspa.outputs.lb_dns_name
  })
}
