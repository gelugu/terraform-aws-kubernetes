data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_subnet" "main" {
  vpc_id                  = data.aws_vpc.main.id
  map_public_ip_on_launch = false
  cidr_block              = cidrsubnet(data.aws_vpc.main.cidr_block, 3, var.subnet_netnum)
  availability_zone       = element(data.aws_availability_zones.available.names, 0)
  tags                    = {
    Name = "subnet-${var.cluster_name}"
  }
}

resource "aws_route_table" "main" {
  vpc_id = data.aws_vpc.main.id
}
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}
resource "aws_route" "nat_gw" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.main.id
}
