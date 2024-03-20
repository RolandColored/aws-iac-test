
variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "eu-central-1"
}

variable "tenants" {
  description = "List of tenants to create."

  type = list(string)
  default = ["bessie", "clarabelle", "penelope"]
}
