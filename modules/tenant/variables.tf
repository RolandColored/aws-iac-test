
variable "tenant_name" {
  description = "Machine-friendly name for the tenant"
  type    = string
}

variable "bucket_id" {
  description = "ID of the S3 bucket used to store function code"
  type    = string
}

variable "bucket_key" {
  description = "Key of the S3 bucket used to store function code"
  type    = string
}

variable "source_code_hash" {
  description = "Hash of the function code"
  type    = string
}

variable "apigateway_id" {
  description = "ID of the API Gateway"
  type    = string
}

variable "apigateway_source_arn" {
  description = "ARN of the API Gateway"
  type    = string
}

