terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.20"
    }
  }
}

provider "docker" {}

resource "docker_network" "observability_net" {
  name = "observability_net"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [name]
  }
}


# Elasticsearch image & container
resource "docker_image" "elasticsearch" {
  name = "docker.elastic.co/elasticsearch/elasticsearch:7.17.0"
}

resource "docker_container" "elasticsearch" {
  name  = "elasticsearch"
  image = docker_image.elasticsearch.name

  ports {
    internal = 9200
    external = 9200
  }

  env = [
    "discovery.type=single-node",
    "ES_JAVA_OPTS=-Xms512m -Xmx512m"
  ]

  networks_advanced {
    name = docker_network.observability_net.name
  }

  restart = "unless-stopped"
}

# Logstash image & container
resource "docker_image" "logstash" {
  name = "docker.elastic.co/logstash/logstash:7.17.0"
}

resource "docker_container" "logstash" {
  name  = "logstash"
  image = docker_image.logstash.name

  ports {
    internal = 5044
    external = 15044
  }

  volumes {
    host_path      = "C:/Users/HP/Downloads/Observability_project/observability_stack/logstash.conf"
    container_path = "/usr/share/logstash/pipeline/logstash.conf"
  }

  networks_advanced {
    name = docker_network.observability_net.name
  }

  depends_on = [docker_container.elasticsearch]
  restart    = "unless-stopped"
}

# Kibana image & container
resource "docker_image" "kibana" {
  name = "docker.elastic.co/kibana/kibana:7.17.0"
}

resource "docker_container" "kibana" {
  name  = "kibana"
  image = docker_image.kibana.name

  ports {
    internal = 5601
    external = 15601
  }

  env = [
    "ELASTICSEARCH_HOSTS=http://elasticsearch:9200"
  ]

  networks_advanced {
    name = docker_network.observability_net.name
  }

  depends_on = [docker_container.elasticsearch]
  restart    = "unless-stopped"
}

resource "docker_image" "filebeat" {
  name = "docker.elastic.co/beats/filebeat:7.17.0"
}

resource "docker_container" "filebeat" {
  name  = "filebeat"
  image = docker_image.filebeat.name

  volumes {
    host_path      = abspath("${path.module}/../simulator/logs")
    container_path = "/var/log/app"
  }

  volumes {
    host_path      = abspath("${path.module}/filebeat.yml")
    container_path = "/usr/share/filebeat/filebeat.yml"
  }

  command = ["filebeat", "-e", "-strict.perms=false", "-c", "/usr/share/filebeat/filebeat.yml"]

  depends_on = [docker_container.logstash]

  networks_advanced {
    name = docker_network.observability_net.name
  }
}

# Grafana image & container
resource "docker_image" "grafana" {
  name = "grafana/grafana:9.5.15"

}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.name

  ports {
    internal = 3000
    external = 3000
  }

  volumes {
    host_path      = abspath("${path.module}/grafana/provisioning")
    container_path = "/etc/grafana/provisioning"
  }

  volumes {
    host_path      = abspath("${path.module}/grafana/dashboards")
    container_path = "/var/lib/grafana/dashboards"
  }

  env = [
    "GF_SECURITY_ADMIN_PASSWORD=admin",
    "GF_DASHBOARDS_JSON_ENABLED=true",
    "GF_DASHBOARDS_JSON_PATH=/var/lib/grafana/dashboards"
  ]

  networks_advanced {
    name = docker_network.observability_net.name
  }

  depends_on = [docker_container.elasticsearch]
  restart    = "unless-stopped"
}
