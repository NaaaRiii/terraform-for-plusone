variable "DATABASE_DEV_USER" {
  type = string
}

variable "DATABASE_DEV_PASSWORD" {
  type      = string
  sensitive = true
}

variable "ecr_image" {
  type        = string
  description = "ECR image URI for the Rails application"
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

# ローカル環境のグローバルIPをCIDRで指定
variable "local_home_ip" {
  type    = string
  default = "49.98.240.79/32"
}
