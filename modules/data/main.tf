# ---------- Base de datos relacional gestionada: RDS MySQL ----------
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project_name}-db-subnets" }
}

resource "aws_db_instance" "this" {
  identifier             = "${var.project_name}-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true
}

# ---------- Base de datos en memoria gestionada: ElastiCache (Valkey) ----------
resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project_name}-cache-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.project_name}-cache"
  description          = "Valkey para sesiones y cache de Moodle"
  engine               = "valkey"
  engine_version       = "8.0"
  node_type            = "cache.t3.micro"
  num_cache_clusters   = 1
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [var.cache_sg_id]
}
