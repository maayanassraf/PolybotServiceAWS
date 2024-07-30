resource "aws_launch_template" "tf-maayana-yolo5-lt" {
  name                 = "tf-${var.owner}-yolo5-lt"
  image_id             = var.ami_id
  instance_type        = data.aws_ec2_instance_types.yolo5_instance_types.instance_types[0]
  user_data            = filebase64("install_docker.sh")
  key_name             = var.key

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name      = "${var.owner}-yolo5-ec2"
      Terraform = "true"
    }
  }

  network_interfaces {
    security_groups = [aws_security_group.tf-maayana-yolo5-sg.id]
    associate_public_ip_address = true
  }
  iam_instance_profile {
    name = var.main-region == true ? aws_iam_instance_profile.yolo5_instance_profile[0].name : "yolo5_instance_profile"
  }
}

data "aws_ec2_instance_types" "yolo5_instance_types" {
  filter {
    name   = "instance-type"
    values = ["t2.medium", "t3.medium"]
  }
}

resource "aws_autoscaling_group" "tf-maayana-yolo5-asg" {
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = var.subnet_ids
  name                = "tf-${var.owner}-yolo5-asg"

  launch_template {
    id      = aws_launch_template.tf-maayana-yolo5-lt.id
    version = aws_launch_template.tf-maayana-yolo5-lt.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}