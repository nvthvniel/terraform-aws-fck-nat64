resource "aws_launch_template" "this" {
  name                    = var.resource_name
  image_id                = data.aws_ami.selected.id
  instance_type           = var.instance_type
  key_name                = var.ssh_key_name
  disable_api_stop        = var.disable_api_stop
  disable_api_termination = var.disable_api_termination


  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.ebs_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.ebs_kms_key
      delete_on_termination = var.ebs_delete_on_termination
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  network_interfaces {
    network_interface_id  = aws_network_interface.this.id
    delete_on_termination = true
  }

  dynamic "tag_specifications" {
    for_each = ["instance", "network-interface", "volume"]

    content {
      resource_type = tag_specifications.value
      tags = {
        Name = var.resource_name
      }
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    TERRAFORM_ENI_ID = aws_network_interface.this.id
    TERRAFORM_EIP_ID = aws_eip.this.id
    TERRAFORM_LOGGING_DEBUG = var.jool_logging_debug
    TERRAFORM_LOGGING_BIB = var.jool_logging_bib
    TERRAFORM_LOGGING_SESSION = var.jool_logging_session
  }))

  # Enforce IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = var.resource_name
  }
}

resource "aws_instance" "main" {

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}
