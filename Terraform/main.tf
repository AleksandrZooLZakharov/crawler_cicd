provider "google" {
  version = "1.4.0"
  project = "docker-235709"
  region  = "europe-west1"
}

#instances
# - Gitlab CI - центр внимания в CI/CD процессе между разными окружениями
# - Dev - стенд для откатки всего в пределах одной виртуальной машины.

resource "google_compute_instance" "mongo" {
  name         = "mongo"
  machine_type = "g1-small"
  zone         = "europe-west1-b"

  metadata {
    ssh-keys = "azakharov77:${file("~/.ssh/gcp_rsa.pub")}"
  }

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "mongo-image"
    }
  }

  # сеть пока простая
  network_interface {
    network       = "default"
    access_config = {}
  }

  # метим тегом
  tags = ["mongo"]

    # провиженинг
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "azakharov77"
      agent       = false
      private_key = "${file("~/.ssh/gcp_rsa")}"
    }
  
    inline = [
      "sudo curl -sSL https://get.docker.com/ | sh",
      "sudo usermod -aG docker `echo $USER`",
      "sudo docker run -d --hostname my-mongo --name some-mongo -e MONGO_INITDB_ROOT_USERNAME=mongo -e MONGO_INITDB_ROOT_PASSWORD=mongo mongo:4-xenial"
    ]
  }

}

resource "google_compute_firewall" "mongo-fw" {
  name    = "mongo-fw"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "27017", "8000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["mongo"]
}

resource "google_compute_instance" "rabbitmq" {
  name         = "rabbitmq"
  machine_type = "g1-small"
  zone         = "europe-west1-b"

  metadata {
    ssh-keys = "azakharov77:${file("~/.ssh/gcp_rsa.pub")}"
  }

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "ubuntu-1604-lts"
    }
  }

  # сеть пока простая
  network_interface {
    network       = "default"
    access_config = {}
  }

  # метим тегом
  tags = ["rabbit"]

  # провиженинг
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "azakharov77"
      agent       = false
      private_key = "${file("~/.ssh/gcp_rsa")}"
    }
  
    inline = [
      "sudo curl -sSL https://get.docker.com/ | sh",
      "sudo usermod -aG docker `echo $USER`",
      "sudo docker run -d -p 80:15672 --hostname my-rabbit --name some-rabbit -e RABBITMQ_DEFAULT_USER=rabbit -e RABBITMQ_DEFAULT_PASS=rabbit rabbitmq:3-management"
    ]
  }


}

resource "google_compute_firewall" "rabbit-fw" {
  name    = "rabbit-fw"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "5672", "5671", "15672", "15671", "8000", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["rabbit"]
}


resource "google_compute_instance" "gitlab-ci" {
  name         = "gitlab-ci"
  machine_type = "n1-standard-1"
  zone         = "europe-west1-b"

  metadata {
    ssh-keys = "azakharov77:${file("~/.ssh/gcp_rsa.pub")}"
  }

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "ubuntu-1604-lts"
      size = "10"
    }
  }

  # сеть пока простая
  network_interface {
    network       = "default"
    access_config = {}
  }

  # метим тегом
  tags = ["gitlab"]

  # провиженинг
  #connection {
  #  type        = "ssh"
  #  user        = "azakharov77"
  #  agent       = false
  #  private_key = "${file("~/.ssh/gcp_rsa")}"
  #}
  #provisioner "remote-exec" {
  #  script = "files/gitlab-deploy.sh"
  #}
}

#firewall rules
resource "google_compute_firewall" "gitlab-fw" {
  name    = "gitlab-fw"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gitlab"]
}



resource "google_compute_instance" "dev" {
  name         = "dev"
  machine_type = "n1-standard-1"
  zone         = "europe-west1-b"

  depends_on = [
    "google_compute_instance.mongo", 
    "google_compute_instance.rabbitmq"
  ]

  metadata {
    ssh-keys = "azakharov77:${file("~/.ssh/gcp_rsa.pub")}"
  }

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "ubuntu-1604-lts"
      size = "10"
    }
  }

  # сеть пока простая
  network_interface {
    network       = "default"
    access_config = {}
  }

  # метим тегом
  tags = ["develop"]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "azakharov77"
      agent       = false
      private_key = "${file("~/.ssh/gcp_rsa")}"
    }
  
    inline = [
      "sudo curl -sSL https://get.docker.com/ | sh",
      "sudo usermod -aG docker `echo $USER`",
      "sudo docker run -d --hostname my-ui --name some-ui -e MONGO=${google_compute_instance.mongo.network_interface.0.network_ip} -e MONGO_PORT=27017 zoolgle/ui:latest cd ui && FLASK_APP=ui.py gunicorn ui:app -b 0.0.0.0",
      "sudo docker run -d --hostname my-crawler --name some-crawler -e MONGO=${google_compute_instance.mongo.network_interface.0.network_ip} -e MONGO_PORT=27017 -e RMQ_HOST=${google_compute_instance.rabbitmq.network_interface.0.network_ip} -e RMQ_QUEUE=raq -e RMQ_USERNAME=rabbit -e RMQ_PASSWORD=rabbit -e CHECK_INTERVAL=30 -e EXCLUDE_URLS='.*github.com' zoolgle/crawler:1.0 python -u crawler/crawler.py https://vitkhab.github.io/search_engine_test_site/"
    ]
  }
}

#firewall rules
resource "google_compute_firewall" "dev-fw" {
  name    = "dev-fw"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gitlab"]
}



 

