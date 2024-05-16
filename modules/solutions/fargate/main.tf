module "elb" {
  source   = "./elb"
  workload = var.workload
  vpc_id   = var.vpc_id
  subnets  = var.elb_subnet_ids
}

module "iam" {
  source   = "./iam"
  workload = var.workload
}

module "ecr" {
  source   = "./ecr"
  workload = var.workload
}

module "vpce" {
  source    = "./vpce"
  vpc_id    = var.vpc_id
  region    = var.region
  subnet_id = var.vpce_subnet_id
}

module "ecs" {
  source                         = "./ecs"
  workload                       = var.workload
  vpc_id                         = var.vpc_id
  subnets                        = var.ecs_subnet_ids
  region                         = var.region
  ecr_vulnerapp_repository_url   = module.ecr.vulnerapp_repository_url
  ecr_cryptominer_repository_url = module.ecr.cryptominer_repository_url
  ecs_task_execution_role_arn    = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn              = module.iam.ecs_task_role_arn
  target_group_arn               = module.elb.target_group_arn
  cryptominer_target_group_arn   = module.elb.cryptminer_target_group_arn
  task_cpu                       = var.ecs_task_cpu
  task_memory                    = var.ecs_task_memory
  enable_service                 = var.enable_fargate_service

  depends_on = [module.vpce]
}
