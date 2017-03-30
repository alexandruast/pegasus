job "fabio" {
  datacenters = [
    "us-east-1"
  ]
  type = "system"
  update {
    stagger = "10s"
    max_parallel = 1
  }
  group "fabio" {
    task "fabio" {
      driver = "exec"
      config {
        command = "fabio-1.3.7-go1.7.4-linux_amd64"
      }
      artifact {
        source = "https://github.com/eBay/fabio/releases/download/v1.3.7/fabio-1.3.7-go1.7.4-linux_amd64"
        options {
          checksum = "sha256:65fce48400bab7650872e5fd76ebe6986d13d341ec7d20fe91de19998f48d9a4"
        }
      }
      resources {
       cpu    = 500 # MHz
       memory = 128 # MB
       network {
         mbits = 10
         port "ui" {
           static = 9998
         }
         port "http" {
           static = 9999
         }
       }
     }
    }
  }
}
