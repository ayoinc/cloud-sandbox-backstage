variable "name" {
  type    = string
  default = "${{ values.name }}"
}

variable "aws_region" {
  type    = string
  default = "${{ values.aws_region }}"
}

variable "environment" {
  type    = string
  default = "${{ values.environment }}"
}

variable "vpc_cidr" {
  type    = string
  default = "${{ values.vpc_cidr }}"
}

variable "azs" {
  type    = number
  default = ${{ values.azs }}
}
