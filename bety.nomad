job "bety" {
  datacenters = [
    "dc1"]
  type        = "service"

  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
    progress_deadline = "10m"
    auto_revert       = false
    canary            = 0
  }

  migrate {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }

  group "web" {
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    ephemeral_disk {
      sticky  = true
      migrate = true
      size    = 32768
    }

    task "web_container" {
      driver = "docker"

      config {
        image = "pecan/bety:5.2.1"
        port_map {
          http = 8000
        }

        extra_hosts = [
          "mylocalhost:${attr.unique.network.ip-address}",
          "nomad-host-ip:${NOMAD_IP_http}",
          "postgres:${NOMAD_IP_http}"
        ]
      }

      resources {
        cpu    = 1000
        memory = 2048
        network {
          mbits = 10
          port "http" {}
        }
      }

      template {
        // TODO: Use Vault for secrets
        data        = <<EOH
{{key "service/bety/environment"}}
EOH
        destination = "secrets/file.env"
        env         = true
      }


      service {
        name = "bety-web"
        tags = [
          "urlprefix-:8000 proto=tcp"]
        port = "http"
        check {
          name         = "tcp-check"
          port         = "http"
          type         = "tcp"
          interval     = "10s"
          timeout      = "2s"
          port         = 8000
          address_mode = "driver"
        }
        check {
          name         = "alive"
          type         = "http"
          path         = "/"
          interval     = "10s"
          timeout      = "2s"
          port         = 8000
          address_mode = "driver"
        }
      }
    }
  }
}
