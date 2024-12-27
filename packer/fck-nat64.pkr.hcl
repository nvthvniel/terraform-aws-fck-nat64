packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# https://github.com/AndrewGuenther/fck-nat/releases
variable "fck_nat_version" {
  description = "Version of fck-nat to install"
  type = string
}

# https://github.com/NICMx/Jool/releases
variable "jool_version" {
  description = "Version of Jool to install"
  type = string
}

variable "ami_regions" {
  description = "Regions to make AMI available in"
  type = list(string)
  default = []
}

variable "ami_users" {
  description = "List of account IDs who can launch AMI"
  type = list(string)
  default = []
}

variable "ami_groups" {
  description = "List of groups who can launch AMI"
  type = list(string)
  default = []
}

variable "virtualization_type" {
  description = "Hypervisor type"
  type = string
  default = "hvm"
}

variable "architecture" {
  description = "Processor type"
  type = string
  default = "arm64"
}

variable "flavor" {
  description = "Operating system name"
  type = string
  default = "al2023"
}

variable "instance_type" {
  description = "EC2 instance types to build on for each architecture"
  type = map(string)
  default = {
    "arm64"  = "t4g.micro"
    "x86_64" = "t3.micro"
  }
}

variable "region" {
  description = "Region to build resources in"
  type = string
  default = "us-west-2"
}

variable "base_image_name" {
  description = "Source AMI name filter"
  type = string
  default = "*al2023-ami-minimal-*-kernel-*"
}

variable "base_image_owner" {
  description = "Source AMI owner aliases or account IDs"
  type = string
  default = "amazon"
}

variable "ssh_username" {
  description = "The username to use when connecting to instance via SSH"
  type = string
  default = "ec2-user"
}

# https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpcs.html
variable "vpc_filters" {
  description = "Identifiers to select VPC for building resources in. Available filters are provided by DescribeVpcs API responses"
  type = map(string)
  default = {
    "isDefault": true
  }
}

# https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSubnets.html
variable "subnet_filters" {
  description = "Identifiers to select subnet for building resources in. Available filters are provided by DescribeSubnets API responses"
  type = map(string)
  default = {
    "mapPublicIpOnLaunch" = true
  }
}

variable "artifact_tags" {
  description = "Key:value pair tags to apply to the generated key-pair, security group, iam profile and role, snapshot, network interfaces and instance that is launched to create the EBS volumes"
  type = map(string)
  default = null
}

source "amazon-ebs" "fck-nat64" {
  ami_name                = "fck-nat64-${var.flavor}-${var.virtualization_type}-${var.fck_nat_version}-${formatdate("YYYYMMDD", timestamp())}-${var.architecture}-ebs"
  ami_virtualization_type = var.virtualization_type
  ami_regions             = var.ami_regions
  ami_users               = var.ami_users
  ami_groups              = var.ami_groups
  instance_type           = "${lookup(var.instance_type, var.architecture, "error")}"
  region                  = var.region
  ssh_username            = var.ssh_username
  temporary_key_pair_type = "ed25519"

  run_tags = merge(
    {
      Name = "fck-nat64-${var.flavor}-${var.virtualization_type}-${var.fck_nat_version}-${formatdate("YYYYMMDD", timestamp())}-${var.architecture}-ebs"
      Jool = "v${var.jool_version}"
      Packer = "true"
    },
    var.artifact_tags
  )

  launch_block_device_mappings {
    device_name = "/dev/xvda"
    encrypted = true
    volume_size = 30
    delete_on_termination = true
  }

  vpc_filter {
    filters = var.vpc_filters
  }

  subnet_filter {
    filters = var.subnet_filters
    most_free = true
  }

  source_ami_filter {
    filters = {
      virtualization-type = var.virtualization_type
      architecture        = var.architecture
      name                = var.base_image_name
      root-device-type    = "ebs"
    }
    owners = [
      var.base_image_owner
    ]
    most_recent = true
  }
}

build {
  name = "fck-nat64"
  sources = ["source.amazon-ebs.fck-nat64"]

  provisioner "shell" {
    inline = [
      "sudo yum install wget -y",
      "wget https://github.com/AndrewGuenther/fck-nat/releases/download/v${var.fck_nat_version}/fck-nat-${var.fck_nat_version}-any.rpm -P /tmp"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo yum install amazon-cloudwatch-agent amazon-ssm-agent iptables -y",
      "sudo yum --nogpgcheck -y localinstall /tmp/fck-nat-${var.fck_nat_version}-any.rpm",
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo dnf install -y kpatch-dnf",
      "sudo dnf kernel-livepatch -y auto",
      "sudo dnf install -y kpatch-runtime",
      "sudo dnf update kpatch-runtime",
      "sudo systemctl enable kpatch.service && sudo systemctl start kpatch.service",
    ]
  }

  # NAT64 using Jool (https://nicmx.github.io/Jool/en/install.html)
  provisioner "shell" {
    inline = [
      "sudo yum install gcc make elfutils-libelf-devel kernel-devel libnl3-devel iptables-devel iptables dkms tar -y",
      "wget https://github.com/NICMx/Jool/releases/download/v${var.jool_version}/jool-${var.jool_version}.tar.gz -P /tmp",
      "tar -xzf /tmp/jool-${var.jool_version}.tar.gz -C /tmp",
      "sudo dkms install /tmp/jool-${var.jool_version}/",
      "cd /tmp/jool-${var.jool_version} && sudo ./configure",
      "cd /tmp/jool-${var.jool_version} && sudo make",
      "cd /tmp/jool-${var.jool_version} && sudo make install"
    ]
  }

  provisioner "file" {
    source = "${path.root}/../service/jool.service"
    destination = "/tmp/jool.service"
  }

  provisioner "file" {
    source = "${path.root}/../service/jool.sh"
    destination = "/tmp/jool.sh"
  }

  # Move files to overcome permissioned denied errors with scp (https://developer.hashicorp.com/packer/docs/provisioners/file)
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/jool.service /lib/systemd/system/jool.service",
      "sudo mv /tmp/jool.sh /etc/init.d/jool"
    ]
  }
}
