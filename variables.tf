variable "aws_access_key" {
  description = "aws active access-key" 
  type        = string
  default = ""
}

variable "aws_secret_key" {
  description = "aws active secret-key"
  type        = string
  default = ""
}

variable "region" {
  description = "The aws region"
  type        = string
  default     = "us-east-1"
}


variable "availability_zones_count" {
  description = "The number of AZs."
  type        = number
  default     = 2
}

variable "start_node_count" {
  description = "eks 그룹을 위해서  처음 시작하는 node 수"
  type        = number
  default     = 2
}


variable "instance_type" {
  description = "eks 노드 타입"
  type        = string
  default     = "t2.medium"
}


variable "project" {
  description = "Name to be used on all the resources as identifier"
  # description = "Name of the project deployment."
  type = string
  default = "TFEksGitCICD"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "10.50.0.0/16"
}

variable "subnet_cidr_bits" {
  description = "The number of subnet bits for the CIDR. create a CIDR with a mask of /24."
  type        = number
  default     = 8
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    "Project"     = "TerraformEKSWorkshop"
    "Environment" = "Development"
    "Owner"       = "mcyang"
  }
}


variable "eks_ver" {
  description = "aws eks version"
  type        = string
  default     = "1.23"
}

variable "cluster_cidr" {
  description = "The CIDR block for the Cluster Access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "eks_nodes_cidr" {
  description = "The CIDR block for the Cluster Access"
  type        = string
  default     = "0.0.0.0/0"
}


