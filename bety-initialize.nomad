job "bety-initialize" {
  datacenters = [
    "dc1"]
  type        = "batch"

  group "setup-group" {
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    task "setup-task" {
      driver = "docker"

      config {
        image = "pecan/bety:5.2.1"


        command = "initialize"
        args    = []
        // Use the following to debug environment issues in a batch job:
        //        command     = "bash"
        //        interactive = true

        extra_hosts = [
          "mylocalhost:${attr.unique.network.ip-address}",
          "postgres:${attr.unique.network.ip-address}"
        ]
      }

      env {
        // Anything here?
      }

      resources {
        cpu    = 500
        memory = 1024
      }
    }
  }
}


