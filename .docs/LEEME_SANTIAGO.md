# Instrucciones para Santiago: módulo de cómputo (ECS + ALB)

## Qué hizo Fran (ya existe en el repo)
- `modules/network`: VPC, 2 subredes públicas, 2 privadas, Security Groups (alb, app, db, cache).
- `modules/data`: RDS MySQL y ElastiCache (Valkey).
- Su `main.tf` raíz ya llama a ambos y expone sus outputs.

## Qué hacer, paso a paso

### 1. Traer el repo de Fran
```bash
git clone <URL-del-repo-de-Fran>
cd Actividad5_iac
git checkout -b compute
```

### 2. Copiar el módulo
Copia la carpeta `modules/compute` de este paquete dentro de `modules/` del repo.

### 3. Conectarlo en el `main.tf` de la raíz (agregar al final)
```hcl
module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  aws_region        = var.aws_region
  app_port          = var.app_port
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.network.alb_sg_id
  app_sg_id         = module.network.app_sg_id

  db_host     = module.data.db_host
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  redis_host  = module.data.redis_host

  moodle_admin_password = var.moodle_admin_password
}
```

### 4. Variable nueva en `variables.tf` (raíz)
```hcl
variable "moodle_admin_password" {
  type      = string
  sensitive = true
}
```
Y en tu `terraform.tfvars` (NO va a git):
```
db_password           = "la_misma_que_uso_Fran"
moodle_admin_password = "Moodle_Admin#2026"
```

### 5. Output nuevo en `outputs.tf` (raíz)
```hcl
output "moodle_url" {
  value = "http://${module.compute.alb_dns_name}"
}
```

### 6. Qué DEBES revisar antes del apply
1. **La imagen** (`moodle_image` en `modules/compute/variables.tf`): abre su página en Docker Hub y confirma que el nombre y la etiqueta existen. Si cambias de imagen, cambia el default.
2. **Variables de entorno** (bloque `environment` en `modules/compute/main.tf`): confirma en la documentación de la imagen cómo se llaman las de base de datos y admin. Los nombres puestos son estilo Bitnami.
3. **Puerto** (`app_port`, 8080 por defecto): si la imagen escucha en otro puerto, cámbialo en `variables.tf` de la raíz.
4. **Clave del admin**: Moodle exige mayúscula, minúscula, número y símbolo.

### 7. Probar
```bash
terraform init
terraform validate
terraform plan
terraform apply
```
- La clave de la base de datos tiene que ser la misma con la que Fran creó RDS. Si Fran ya hizo `apply`, usen el mismo estado: lo más simple es que UNO solo ejecute el apply final de todo.
- Cuando termine, abre `moodle_url`. La primera vez Moodle tarda varios minutos en instalarse y el ALB puede mostrar 502/503 mientras tanto.
- Si falla, mira los logs en CloudWatch, grupo `/ecs/a5iac-moodle`, y el servicio en ECS, pestaña "Events".

### 8. Evidencia para el PDF
Capturas de: el cluster y el servicio en ECS (estado Running), la task definition con la imagen, el ALB con su DNS, Moodle cargando en el navegador, y los logs. Después, `terraform destroy`.

## Qué NO está hecho (mencionarlo como mejoras en las conclusiones)
- EFS para `moodledata` (sin él, los archivos se pierden si el contenedor se reinicia).
- Conectar Moodle a Valkey (se configura desde el panel de admin de Moodle).
- HTTPS, Secrets Manager para las claves y autoescalado.
