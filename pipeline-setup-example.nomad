job "pipeline-setup-example" {
  datacenters = [
    "dc1"]
  type        = "batch"

  parameterized {
    payload       = "forbidden"
    meta_required = [
      "CLOWDER_BASE_URL",
      "CLOWDER_USERNAME",
      "CLOWDER_PASSWORD",
      "CLOWDER_SPACE",
      "CAPTURE_SENSOR_NAME",
      "CAPTURE_TIMESTAMP",
      "CAPTURE_RAW_DATA_URL",
      "CAPTURE_RAW_DATA_MD5",
      "BETYDB_KEY"
    ]
  }

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
        image = "terraref/terrautils:1.5"


        command = "python"
        args    = [
          "/local/pipeline_setup_example.py"
        ]
        // Use the following to debug environment issues in a batch job:
        //        command     = "bash"
        //        interactive = true

        port_map {
          http = 9000
        }

        extra_hosts = [
          "mylocalhost:${attr.unique.network.ip-address}",
          "nomad-host-ip:${NOMAD_IP_http}",
          "clowder:${NOMAD_IP_http}",
          "rabbitmq:${NOMAD_IP_http}",
          "mongo:${NOMAD_IP_http}",
          "elasticsearch:${NOMAD_IP_http}"
        ]

        volumes = [
          "sensor-metadata/sensor-metadata-master:/home/extractor/sites/ua-mac/sensor-metadata",
          "capture_raw_data:/data"
        ]
      }

      artifact {
        source      = "https://gist.githubusercontent.com/julianpistorius/4f1281026288141ad547d78eec06523c/raw/0750f2ed7b58f0be0474203a2339041b8f0aa4e0/pipeline_setup_example.py"
        destination = "/local"

        options {
          checksum = "md5:520e7a9e4ef934b76cd4065649d8e916"
        }
      }

      artifact {
        source      = "https://github.com/terraref/sensor-metadata/archive/master.zip"
        destination = "sensor-metadata"

        options {
          checksum = "md5:9562ab56309e8f796d52cb38cf14c3b9"
        }
      }

      artifact {
        source      = "${NOMAD_META_CAPTURE_RAW_DATA_URL}"
        destination = "capture_raw_data"

        options {
          checksum = "md5:${CAPTURE_RAW_DATA_MD5}"
        }
      }

      env {
        CLOWDER_BASE_URL     = "${NOMAD_META_CLOWDER_BASE_URL}"
        CLOWDER_USERNAME     = "${NOMAD_META_CLOWDER_USERNAME}"
        CLOWDER_PASSWORD     = "${NOMAD_META_CLOWDER_PASSWORD}"
        CLOWDER_SPACE        = "${NOMAD_META_CLOWDER_SPACE}"
        CAPTURE_SENSOR_NAME  = "${NOMAD_META_CAPTURE_SENSOR_NAME}"
        CAPTURE_TIMESTAMP    = "${NOMAD_META_CAPTURE_TIMESTAMP}"
        CAPTURE_RAW_DATA_URL = "${NOMAD_META_CAPTURE_RAW_DATA_URL}"
        CAPTURE_RAW_DATA_MD5 = "${NOMAD_META_CAPTURE_RAW_DATA_MD5}"
        BETYDB_KEY           = "${NOMAD_META_BETYDB_KEY}"
      }

      resources {
        cpu    = 500
        memory = 1024
        network {
          mbits = 10
          port "http" {}
        }
      }
    }
  }
}


