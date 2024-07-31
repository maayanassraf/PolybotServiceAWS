resource "aws_autoscaling_policy" "scale_up" {
  name                   = "yolo5_scale_up"
  autoscaling_group_name = aws_autoscaling_group.tf-yolo5-asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 120
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  alarm_name          = "yolo5_scale_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "60"
  statistic           = "Average"
  period              = 30
  evaluation_periods  = 1
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.tf-yolo5-asg.name
  }
}