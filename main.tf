terraform {
  required_version = ">= 0.14.0"
  required_providers {
    maas = {
      source  = "maas/maas"
      version = "2.2.0"
    }
  }
}

provider "maas" {
  api_version = var.maas_api_version
  api_key     = var.maas_api_key
  api_url     = var.maas_api_url
}

resource "maas_space" "space" {
  for_each = var.spaces

  name = each.key
}

resource "maas_fabric" "fabric" {
  for_each = var.fabrics

  name = each.key
}

resource "maas_vlan" "vlan" {
  depends_on = [maas_fabric.fabric, maas_space.space]
  for_each   = var.vlans

  fabric  = each.value.fabric
  vid     = each.value.vid
  mtu     = each.value.mtu
  dhcp_on = each.value.dhcp_on
  space   = each.value.space
}

resource "maas_subnet" "subnet" {
  depends_on = [maas_fabric.fabric, maas_vlan.vlan]
  for_each   = var.subnets

  fabric      = each.value.fabric
  vlan        = maas_vlan.vlan["${each.value.fabric}-${each.value.vlan}"].id
  name        = each.value.name
  cidr        = each.value.cidr
  gateway_ip  = each.value.gateway_ip
  dns_servers = each.value.dns_servers

  dynamic "ip_ranges" {

    # loop over services
    for_each = each.value.ip_ranges

    # and name the iterator variable
    iterator = ip_range

    # content keyword separates the iteration syntax and content
    content {
      type     = ip_range.value.type
      start_ip = ip_range.value.start_ip
      end_ip   = ip_range.value.end_ip
      comment  = ip_range.value.comment
    }
  }
}

resource "maas_tag" "machines_vms_tags" {
  for_each = var.tags
  name     = each.key
}

locals {
  disks = flatten([
    for disk, details in var.disks : [
      for machine in details.machines : {
        machine        = machine.name
        name           = details.name
        size_gigabytes = details.size_gigabytes
        model          = machine.model
        serial         = machine.serial
        is_boot_device = details.is_boot_device
        partitions     = details.partitions
      }
    ]
  ])
}

resource "terraform_data" "remove_auto-enlisted_disks" {
  for_each = var.default_disks

  provisioner "local-exec" {
    command = <<-EOT
      %{for disk in each.value.disks~}
      maas $PROFILE block-device delete $SYSTEM_ID ${disk.id}
      %{endfor~}
    EOT
    environment = {
      SYSTEM_ID = each.value.system_id
      PROFILE   = var.maas_admin_details.username
    }
  }
}

resource "maas_block_device" "disks" {
  depends_on = [terraform_data.remove_auto-enlisted_disks]
  for_each = {
    for disk in local.disks : "${disk.machine}-${disk.name}" => disk
  }

  machine        = each.value.machine
  name           = each.value.name
  size_gigabytes = each.value.size_gigabytes
  model          = each.value.model
  serial         = each.value.serial
  is_boot_device = each.value.is_boot_device

  dynamic "partitions" {
    for_each = each.value.partitions
    content {
      size_gigabytes = partitions.value.size_gigabytes
      fs_type        = partitions.value.fs_type
      mount_point    = partitions.value.mount_point
    }
  }
}