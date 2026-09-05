# Домашнее задание кОтказоустойчивость в облаке» - `Яковлев Кирилл`


### Задание 1
`Что нужно сделать:`

`Возьмите за основу решение к заданию 1 из занятия «Подъём инфраструктуры в Яндекс Облаке».`

`Теперь вместо одной виртуальной машины сделайте terraform playbook, который:`
`создаст 2 идентичные виртуальные машины. Используйте аргумент count для создания таких ресурсов;`
`создаст таргет-группу. Поместите в неё созданные на шаге 1 виртуальные машины;`
`создаст сетевой балансировщик нагрузки, который слушает на порту 80, отправляет трафик на порт 80 виртуальных машин и` `http healthcheck на порт 80 виртуальных машин.`
`Рекомендуем изучить документацию сетевого балансировщика нагрузки для того, чтобы было понятно, что вы сделали.`

`Установите на созданные виртуальные машины пакет Nginx любым удобным способом и запустите Nginx веб-сервер на порту 80.`

`Перейдите в веб-консоль Yandex Cloud и убедитесь, что:`

`созданный балансировщик находится в статусе Active,`
`обе виртуальные машины в целевой группе находятся в состоянии healthy.`
`Сделайте запрос на 80 порт на внешний IP-адрес балансировщика и убедитесь, что вы получаете ответ в виде дефолтной` `страницы Nginx.`
`В качестве результата пришлите:`

`1. Terraform Playbook.`

`2. Скриншот статуса балансировщика и целевой группы.`

`3. Скриншот страницы, которая открылась при запросе IP-адреса балансировщика.`

### Решение 1

## Файл Terraform Playbook 

[Ссылка на файл Terraform Playbook ](main.tf)

```
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
```

`Скриншот статуса балансировщика и целевой группы.`
![task_balancer_target](https://github.com/djimboliv/8-03-hw/tree/main/img/task_balancer_target.png)

`Скриншот страницы, которая открылась при запросе IP-адреса балансировщика.`
![task_welcome_nginx](https://github.com/djimboliv/8-03-hw/tree/main/img/task_welcome_nginx.png)
