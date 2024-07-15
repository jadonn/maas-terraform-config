variable "maas_api_version" {
  type    = string
  default = "2.0"
}

variable "maas_api_key" {
  type = string
}

variable "maas_api_url" {
  type = string
}

variable "fabrics" {
  type = set(string)
}

variable "spaces" {
  type = set(string)
}

variable "vlans" {
  type = map(object({
    fabric  = string
    space   = string
    mtu     = number
    dhcp_on = bool
    vid     = number
  }))
}

variable "subnets" {
  type = map(object({
    fabric      = string
    cidr        = string
    vlan        = string
    name        = optional(string, "")
    gateway_ip  = optional(string)
    dns_servers = optional(list(string))
    ip_ranges = map(object({
      type     = optional(string, "reserved")
      comment  = optional(string, "")
      start_ip = string
      end_ip   = string
    }))
  }))
}

variable "tags" {
  type = set(string)
}

variable "disks" {
  description = "Storage configuration for each group of machines"
  type = list(object({
    machines = list(object({
      name   = string
      model  = string
      serial = string
    }))
    name           = string
    is_boot_device = optional(bool, false)
    size_gigabytes = number
    partitions = optional(list(object({
      size_gigabytes = number
      fs_type        = optional(string)
      mount_point    = optional(string)
    })), [])
  }))
}

# Example:

# disks = [{
#   machines = [
#     {
#       name   = "node02",
#       model  = "KINGSTON SV300S3",
#       serial = "50026B775A0211AE"
#     },
#     {
#       name   = "node07",
#       model  = "KINGSTON SV300S3",
#       serial = "50026B775A0214D3"
#   }]
#   name           = "sda"
#   size_gigabytes = 120
#   partitions = [
#     {
#       size_gigabytes = 1
#       fs_type        = "fat32"
#       mount_point    = "/boot/efi"
#     },
#     {
#       size_gigabytes = 90
#       fs_type        = "ext4"
#       mount_point    = "/"
#     },
#     {
#       size_gigabytes = 15
#       fs_type        = "ext4"
#       mount_point    = "/home"
#     }
#   ]
#   },
#   {
#     machines = [
#       {
#         name   = "node02",
#         model  = "KINGSTON SM2280S",
#         serial = "50026B725A030B0A"
#       },
#       {
#         name   = "node07",
#         model  = "KINGSTON SM2280S",
#         serial = "50026B725A030BCF"
#     }]
#     name           = "sdb"
#     size_gigabytes = 120
#     partitions = [
#       {
#         size_gigabytes = 20
#         fs_type        = "ext4"
#         mount_point    = "/media"
#     }]
# }]

variable "default_disks" {
  description = "List of auto-detected disks to be deleted"
  type = map(object({
    system_id = string
    disks = list(object({
      id     = string
      name   = optional(string)
      model  = optional(string)
      serial = optional(string)
      size   = optional(string)
    }))
  }))
}

variable "maas_admin_details" {
  description = "MAAS connection information"
  type = object({
    username     = string
    password     = string
    email        = string
    ssh_key_path = string
    api_key      = string
    import_key   = optional(string)
  })
  sensitive = false
}