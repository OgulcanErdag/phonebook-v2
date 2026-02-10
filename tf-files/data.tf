# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc

data "aws_vpc" "selected" {
  default = true
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
# https://docs.aws.amazon.com/linux/al2023/ug/ec2.html

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets

data "aws_subnets" "pb-subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  # filter {
  #   name   = "tag:Name"
  #   values = ["default*"] # our ondia aws account have more than one default VPC for RDS . This block for us.
  # }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone

data "aws_route53_zone" "selected" {
  name = var.hosted-zone
}
