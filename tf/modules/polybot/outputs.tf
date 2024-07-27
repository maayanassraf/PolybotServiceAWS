

output "polybot_instance_type" {
  value = data.aws_ec2_instance_types.polybot_instance_types.instance_types[0]
}
