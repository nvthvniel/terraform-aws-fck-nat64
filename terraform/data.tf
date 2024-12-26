data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ami" "selected" {
  most_recent = true

  owners = [
    data.aws_caller_identity.current.account_id
  ]

  filter {
    name = "name"
    values = [
      var.ami_name
    ]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

data "aws_vpc" "selected" {
  id = data.aws_subnet.selected.vpc_id
}

data "aws_iam_policy_document" "permission_policy" {
  statement {
    sid = "HAMode"

    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Name"
      values   = [var.resource_name]
    }
  }

  statement {
    sid = "ManageEIPAllocation"

    actions = [
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
    ]

    resources = [
      aws_eip.this.arn
    ]
  }

  statement {
    sid = "ManageEIPNetworkInterface"

    actions = [
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
    ]

    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Name"
      values   = [var.resource_name]
    }
  }
}

data "aws_iam_policy_document" "trust_relationship" {
  statement {
    sid = "EC2"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}