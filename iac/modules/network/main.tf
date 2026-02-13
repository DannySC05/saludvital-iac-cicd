data "aws_availability_zones" "available" {}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project}-${var.environment}-private-${count.index}"
  }
}

resource "aws_security_group" "lambda_sg" {
  name   = "${var.project}-${var.environment}-lambda-sg"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group" "rds_sg" {
  name   = "${var.project}-${var.environment}-rds-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }
}
