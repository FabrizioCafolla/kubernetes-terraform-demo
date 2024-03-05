module "cluster" {
  source = "./modules/cluster"

  namespace_name = var.namespace_name
}
