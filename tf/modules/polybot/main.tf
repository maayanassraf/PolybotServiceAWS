
resource "aws_instance" "app_server" {
  count = length(var.subnet_ids)

  ami                         = var.ami_id
  instance_type               = data.aws_ec2_instance_types.polybot_instance_types.instance_types[0]
  vpc_security_group_ids      = [aws_security_group.tf-polybot-sg.id]
  subnet_id                   = var.subnet_ids[count.index]
  associate_public_ip_address = true
  key_name                    = var.key
  iam_instance_profile        =  var.main-region == true ? aws_iam_instance_profile.polybot_instance_profile[0].name : "polybot_instance_profile"
  user_data                   = file("install_docker.sh")

  tags = {
    Name = "${var.owner}-polybot-ec2"
    Terraform = "true"
  }
}

data "aws_ec2_instance_types" "polybot_instance_types" {
  filter {
    name   = "instance-type"
    values = ["t2.micro", "t3.micro"]
  }
}

data "aws_route53_zone" "hosted_zone_id" {
  name         = var.hosted_zone_name
}