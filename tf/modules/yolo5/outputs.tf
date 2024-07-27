output "launch_template_id" {
  value = aws_launch_template.tf-maayana-yolo5-lt.id
}

output "yolo5_instance_type" {
  value = data.aws_ec2_instance_types.yolo5_instance_types.instance_types[0]
}