data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

locals {
  zones = slice(data.aws_availability_zones.available.names, 0, 2)

  public_cidrs = [
    "10.20.1.0/24",
    "10.20.2.0/24"
  ]

  database_cidrs = [
    "10.20.11.0/24",
    "10.20.12.0/24"
  ]
}

resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ticket-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ticket-internet-gateway"
  }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = local.zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "ticket-public-${count.index + 1}"
  }
}

resource "aws_subnet" "database" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.database_cidrs[count.index]
  availability_zone       = local.zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "ticket-database-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ticket-public-routes"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ticket-database-routes"
  }
}

resource "aws_route_table_association" "database" {
  count = 2

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}
resource "aws_subnet" "database_extra" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.13.0/24"
  availability_zone       = "us-east-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "ticket-database-extra"
  }
}

resource "aws_route_table_association" "database_extra" {
  subnet_id      = aws_subnet.database_extra.id
  route_table_id = aws_route_table.database.id
}