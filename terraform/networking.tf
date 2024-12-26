resource "aws_network_interface" "this" {
  source_dest_check = false
  subnet_id         = var.subnet_id
  security_groups   = [aws_security_group.this.id]

  tags = {
    Name = var.resource_name
  }
}

resource "aws_eip" "this" {
  network_interface = aws_network_interface.this.id
  domain            = "vpc"

  tags = {
    Name = var.resource_name
  }

  depends_on = [
    aws_network_interface.this
  ]
}

resource "aws_security_group" "this" {
  name        = var.resource_name
  description = "Allow VPC ingress to NAT instance"
  vpc_id      = data.aws_subnet.selected.vpc_id

  tags = {
    Name = var.resource_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_ipv4" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = data.aws_vpc.selected.cidr_block
  ip_protocol = -1
}

resource "aws_vpc_security_group_ingress_rule" "vpc_ipv6" {
  security_group_id = aws_security_group.this.id

  cidr_ipv6   = data.aws_vpc.selected.ipv6_cidr_block
  ip_protocol = -1
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

resource "aws_vpc_security_group_egress_rule" "all_ipv6" {
  security_group_id = aws_security_group.this.id

  cidr_ipv6   = "::/0"
  ip_protocol = -1
}

resource "aws_route" "nat" {
  count = length(var.route_table_ids)

  route_table_id         = var.route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.this.id
}

resource "aws_route" "nat64" {
  count = length(var.route_table_ids)

  route_table_id              = var.route_table_ids[count.index]
  destination_ipv6_cidr_block = "64:ff9b::/96"
  network_interface_id        = aws_network_interface.this.id
}