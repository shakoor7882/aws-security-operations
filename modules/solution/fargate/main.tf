module "elb" {
  source   = "./elb"
  workload = var.workload
  vpc_id   = module.vpc.vpc_id
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

module "ecs" {
  source                      = "./ecs"
  workload                    = var.workload
  vpc_id                      = var.vpc_id
  subnets                     = var.ecs_subnet_ids
  region                      = var.region
  ecr_repository_url          = module.ecr.repository_url
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.iam.ecs_task_role_arn
  target_group_arn            = module.elb.target_group_arn
  task_cpu                    = var.ecs_task_cpu
  task_memory                 = var.ecs_task_memory
}
