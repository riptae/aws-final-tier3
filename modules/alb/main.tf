resource "aws_lb" "this" {
  name = "${var.name_prefix}-alb"
  load_balancer_type = "application"
  internal = false

  security_groups = [var.alb_sg_id]
  subnets = var.public_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "web" {
  name = "${var.name_prefix}-web-tg"  
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "instance"

  health_check {
    enabled = true
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
  
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-web-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_target_group_attachment" "web" {
  count = length(var.web_instance_ids)
  target_group_arn = aws_lb_target_group.web.arn
  target_id = var.web_instance_ids[count.index]
  port = 80
}