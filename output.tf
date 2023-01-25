output "instance_dns" {
  value = aws_instance.web.*.public_dns
}

output "lb-dns" {
  value = aws_lb.web-lb.dns_name
}
