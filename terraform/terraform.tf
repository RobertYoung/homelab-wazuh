terraform {
  backend "s3" {
    bucket = "terraform-iamrobertyoung"
    key    = "projects/homelab-wazuh/main/tfstate.json"
    region = "eu-west-1"
  }
}
