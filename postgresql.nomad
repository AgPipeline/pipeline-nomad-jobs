job "postgresql" {
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

  group "database" {
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
      size    = 300
    }

    task "postgresql_container" {
      driver = "docker"

      config {
        image = "postgres:9.6.15-alpine"
        port_map {
          db = 5432
        }
      }

      template {
        // TODO: Use Vault for secrets
        data = <<EOH
# Environment variables required to work:
# POSTGRES_PASSWORD = "some-long-password-here"
{{key "service/postgresql/environment"}}
EOH
        destination = "secrets/file.env"
        env         = true
      }

      resources {
        cpu    = 500
        memory = 512
        network {
          mbits = 10
          port "db" {}
        }
      }

      service {
        name = "postgresql"
        tags = [
          "urlprefix-:5432 proto=tcp"
        ]
        port = "db"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
