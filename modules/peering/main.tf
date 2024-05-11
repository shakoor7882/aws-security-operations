data "aws_caller_identity" "peer" {}

locals {
  account_id = data.aws_caller_identity.peer.account_id
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = var.security_requester_vpc_id
  peer_vpc_id   = var.solution_accepter_vpc_id
  peer_owner_id = local.account_id

  # Auto-accept must be false for x-region, and must use accepter
  auto_accept = true

  tags = {
    Side = "Requester"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_vpc_peering_connection_options" "requester" {
  # As options can't be set until the connection has been accepted
  # create an explicit dependency on the accepter.
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "security_to_solution" {
  route_table_id            = var.security_requester_route_table_id
  destination_cidr_block    = var.solution_accepter_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "solution_to_security" {
  route_table_id            = var.solution_accepter_route_table_id
  destination_cidr_block    = var.security_requester_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
