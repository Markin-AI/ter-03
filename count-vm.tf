resource "yandex_compute_instance" "web" {
  depends_on = [yandex_compute_instance.db]

  count = var.counts

  name        = "${var.vms_name}-${count.index + 1}"
  hostname        = "${var.vms_name}-${count.index + 1}"
  platform_id = var.vms_resources.platform_id
  metadata = {
  serial-port-enable = 1
  ssh-keys           = local.ssh_key
  }

  resources {
    cores         = var.vms_resources.cores
    memory        = var.vms_resources.memory
    core_fraction = var.vms_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      type     = var.vms_resources.disk_type
      size     = var.vms_resources.disk_size
    }
  }


  scheduling_policy { preemptible = var.vms_resources.preemptible }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    security_group_ids = [yandex_vpc_security_group.example.id]
    nat = var.vms_resources.nat
  }
}