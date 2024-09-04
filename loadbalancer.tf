locals {
  control_plane_lb_internal_ip = var.control_plane_internal_ip != null ? var.control_plane_internal_ip : cidrhost(var.node_ipv4_cidr, 5)
}

resource "hcloud_load_balancer" "control_plane" {
  count = var.enable_control_plane_lb ? 1 : 0
  name               = "control_plane_lb"
  load_balancer_type = var.control_plane_lb_type
  network_zone       = "eu-central"
  delete_protection  = true
  labels = {
    "cluster" = var.cluster_name,
    "role"    = "control-plane"
  }
}

resource "hcloud_load_balancer_network" "control_plane" {
  count = var.enable_control_plane_lb ? 1 : 0
  load_balancer_id        = hcloud_load_balancer.control_plane[0].id
  network_id              = hcloud_network.this.id
  ip                      = local.control_plane_lb_internal_ip
  enable_public_interface = var.enable_control_plane_lb_public_ip
  depends_on = [
    hcloud_network_subnet.nodes
  ]
}

resource "hcloud_load_balancer_service" "control_plane_kubeapi" {
  count = var.enable_control_plane_lb ? 1 : 0
  load_balancer_id = hcloud_load_balancer.control_plane[0].id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
  proxyprotocol    = true
}

resource "hcloud_load_balancer_service" "control_plane_talosapi" {
  count = var.enable_control_plane_lb ? 1 : 0
  load_balancer_id = hcloud_load_balancer.control_plane[0].id
  protocol         = "tcp"
  listen_port      = 50000
  destination_port = 50000
  proxyprotocol    = true
}

resource "hcloud_load_balancer_target" "control_plane_target" {
  count = var.enable_control_plane_lb ? 1 : 0
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.control_plane[0].id
  label_selector   = "role=control-plane"
  use_private_ip   = true
}
