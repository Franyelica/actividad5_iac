# ---------- Logs ----------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 3
}

# ---------- Rol para que ECS pueda arrancar la tarea ----------
resource "aws_iam_role" "task_execution" {
  name = "${var.project_name}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------- Cluster ECS ----------
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

# ---------- Balanceador (ALB) ----------
resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "this" {
  name        = "${var.project_name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # obligatorio con Fargate

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# ---------- Task definition: el contenedor de Moodle ----------
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "moodle"
      image     = var.moodle_image
      essential = true

      portMappings = [{
        containerPort = var.app_port
        protocol      = "tcp"
      }]

      # Nombres verificados en la documentacion de oksigenia/moodle (Docker Hub).
      # Son los nombres nativos de la imagen; los de estilo Bitnami solo se
      # aceptan por compatibilidad.
      environment = [
        { name = "MOODLE_URL", value = "http://${aws_lb.this.dns_name}" },
        { name = "MOODLE_DB_TYPE", value = "mysqli" },
        { name = "MOODLE_DB_HOST", value = var.db_host },
        { name = "MOODLE_DB_PORT", value = "3306" },
        { name = "MOODLE_DB_NAME", value = var.db_name },
        { name = "MOODLE_DB_USER", value = var.db_username },
        { name = "MOODLE_DB_PASSWORD", value = var.db_password },
        { name = "MOODLE_ADMIN_USER", value = var.moodle_admin_user },
        { name = "MOODLE_ADMIN_PASSWORD", value = var.moodle_admin_password },
        # Sesiones y cache de aplicacion en Valkey (ElastiCache)
        { name = "MOODLE_REDIS_HOST", value = var.redis_host },
        { name = "MOODLE_REDIS_PORT", value = "6379" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "moodle"
        }
      }
    }
  ])
}

# ---------- Servicio ECS ----------
resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # Moodle tarda varios minutos en instalarse la primera vez
  health_check_grace_period_seconds = 600

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.app_sg_id]
    assign_public_ip = true # sin NAT, necesita IP publica para bajar la imagen
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "moodle"
    container_port   = var.app_port
  }

  depends_on = [aws_lb_listener.http]
}
