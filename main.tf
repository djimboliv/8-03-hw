terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = "<ВАШ_IAM_ТОКЕН>"
  cloud_id  = "<ВАШ_CLOUD_ID>"
  folder_id = "<ВАШ_FOLDER_ID>"
  zone      = "ru-central1-a"
}

# Создаем сеть
resource "yandex_vpc_network" "network-1" {
  name = "network-1"
}

# Создаем подсеть
resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Получаем ID образа Ubuntu
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts"
}

# 1. Создаем 2 идентичные ВМ с помощью аргумента count
resource "yandex_compute_instance" "vm" {
  count = 2
  name  = "nginx-vm-${count.index + 1}"
  zone  = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  # Устанавливаем Nginx через cloud-init
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    user-data = <<-EOF
      #cloud-config
      packages:
        - nginx
      runcmd:
        - systemctl enable nginx
        - systemctl start nginx
    EOF
  }
}

# 2. Создаем таргет-группу и помещаем в нее ВМ
resource "yandex_lb_target_group" "target-group-1" {
  name = "nginx-target-group"

  dynamic "target" {
    for_each = yandex_compute_instance.vm
    content {
      subnet_id = yandex_vpc_subnet.subnet-1.id
      address   = target.value.network_interface.0.ip_address
    }
  }
}

# 3. Создаем сетевой балансировщик нагрузки
resource "yandex_lb_network_load_balancer" "lb-1" {
  name = "nginx-network-load-balancer"

  listener {
    name = "nginx-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.target-group-1.id

    healthcheck {
      name = "http-healthcheck"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

# Выводим внешний IP-адрес балансировщика в консоль
output "load_balancer_public_ip" {
  description = "Public IP address of the load balancer"
  value       = yandex_lb_network_load_balancer.lb-1.listener.*.external_address_spec[0].*.address
}