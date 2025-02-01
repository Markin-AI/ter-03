
resource "yandex_compute_disk" "disks" {
  count = 3

  name     = "disk-${count.index}"
  type     = var.disks_resources.disk_type
  size     = var.disks_resources.disk_size
}

resource "yandex_compute_instance" "storage" {
  name        = var.vms_name_storage
  hostname        = var.vms_name_storage
  depends_on = [ yandex_compute_disk.disks ]
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
    }
  }
  dynamic secondary_disk {
    for_each = yandex_compute_disk.disks[*].id
      content {
        disk_id = secondary_disk.value
      }
  }

  scheduling_policy { preemptible = var.vms_resources.preemptible }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat = var.vms_resources.nat
  }
}

resource "null_resource" "web_hosts_provision" {
  depends_on = [yandex_compute_instance.storage]
  
  provisioner "local-exec" {
    command = "cat ~/.ssh/id_ed25519 | ssh-add -"
  }

 provisioner "local-exec" {
    command = "sleep 120"
  }

  provisioner "local-exec" {
    command  = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -i ${path.module}/hosts.cfg ${path.module}/test.yml"
    on_failure = continue 
    environment = { ANSIBLE_HOST_KEY_CHECKING = "False" }
  }
    triggers = {
      always_run         = "${timestamp()}" 
      playbook_src_hash  = file("${path.module}/test.yml") 
      ssh_public_key     = local.ssh_key 
    }
  }