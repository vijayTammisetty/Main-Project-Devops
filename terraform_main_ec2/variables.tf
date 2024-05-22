variable "region" {
  description = "AWS region"
  type = string
  default = "us-west-1"
}

variable "vpc-name" {
  description = "VPC Name for our Jumphost server"
  type = string
  default = "Jumphost-or-main-vpc"
}

variable "igw-name" {
  description = "Internet Gate Way Name for our Jumphost server"
  type = string
  default = "Jumphost-main-igw"
}

variable "subnet-name1" {
  description = "Subnet Name for our Jumphost server"
  type = string
  default = "Jumphost-main-subnet1"
}

variable "subnet-name2" {
  description = "Subnet Name for our Jumphost server"
  type = string
  default = "Jumphost-main-subnet2"
}


variable "rt-name" {
  description = "Route Table Name for our Jumphost server"
  type = string
  default = "Jumphost-main-rt"
}

variable "sg-name" {
  description = "Security Group for our Jumphost server"
  type = string
  default = "Jumphost-main-sg"
}


variable "iam-role" {
  description = "IAM Role for the Jumphost Server"
  type = string
  default = "Jumphost-iam-role"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0cbe318e714fc9a82" // Replace with the latest AMI ID for your region
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.large"
}

variable "key_name" {
  description = "EC2 keypair"
  type        = string
  default     = "west-key"
}

variable "instance_name" {
  description = "EC2 Instance name for the jumphost server"
  type        = string
  default     = "Jumphost-server"
}
#