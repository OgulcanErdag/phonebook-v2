output "websiteurl" {
  value = "http://${aws_route53_record.phonebook.name}"
}

output "dns-name" {
  value = "http://${aws_lb.app-lb.dns_name}"
}

output "db-addr" {
  value = aws_db_instance.db_server.address # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance#attribute-reference
}

output "db-endpoint" {
  value = aws_db_instance.db_server.endpoint
}

# Note:
# endpoint - The connection endpoint in address:port format.
# Endpoint :
# address - Specifies the DNS address of the DB instance.
