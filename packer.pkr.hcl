packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ami_name" {
  type    = string
  default = "pipeline-ami"
}

source "amazon-ebs" "pipeline" {
  region                  = var.aws_region
  instance_type           = "t2.micro"
  ami_name                = "${var.ami_name}-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"] # Canonical Ubuntu owner
    most_recent = true
  }
  ssh_username = "ubuntu"
}

build {
  name    = "pipeline-ami-build"
  sources = [
    "source.amazon-ebs.pipeline"
  ]

  provisioner "shell" {
    inline = [
      "echo '--- Pipeline Build Start ---'",
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "systemctl enable nginx",
      "echo 'Hello from Pipeline-built AMI!' | sudo tee /var/www/html/index.html",
      "echo '--- Pipeline Build Complete ---'"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
