output "instance_public_ip" {
  description = "Public IP address of the demo EC2 instance"
  value       = aws_instance.app.public_ip
}

output "application_url" {
  description = "HTTP URL for the demo application"
  value       = "http://${aws_instance.app.public_ip}"
}
