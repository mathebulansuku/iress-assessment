locals {
  common_tags = merge({
    Project = var.project,
    Env     = var.environment,
  }, var.extra_tags)
}

