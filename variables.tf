/*
Network Address	Mask bits   hosts
172.28.0.0      /27         30

Subnet address	Netmask	          Range of addresses	          Useable IPs	                Hosts
172.28.0.0/28	  255.255.255.240	  172.28.0.0 - 172.28.0.15	    172.28.0.1 - 172.28.0.14	  14		
172.28.0.16/28	255.255.255.240	  172.28.0.16 - 172.28.0.31	    172.28.0.17 - 172.28.0.30	  14	
*/

#
# vpc-subnets.tf
#
variable "credentialsfile" {
  default = "/Users/Fer/.aws/credentials"
}

variable "region" {
  default = "us-east-1"
}

variable "vpc-fullcidr" {
  default     = "172.28.0.0/27"
  description = "the vpc cdir"
}

variable "StoreOneSNPublic-CIDR" {
  default     = "172.28.0.0/28"
  description = "the cidr of the subnet"
}

#
# ec2-ubuntu
#
variable "AmiLinux" {
  type = "map"

  default = {
    us-east-1 = "ami-0a313d6098716f372" # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type -  (64-bit x86)
  }

  description = "Showing the map feature"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default     = "myKey"
  description = "the ssh key to use in the EC2 machines"
}
