# actividad5_iac: Moodle en AWS con Terraform, CI/CD y observabilidad

Integrantes: Franyelica García, Santiago Castaño

## Arquitectura

| Capa | Servicio | Módulo |
|---|---|---|
| Red | VPC, subredes públicas/privadas, Security Groups encadenados | `modules/network` |
| Datos | RDS MySQL + ElastiCache Valkey | `modules/data` |
| Cómputo | ECS Fargate + ALB (imagen `oksigenia/moodle:4.5`) | `modules/compute` |
| Observabilidad | SNS (correo), 10 alarmas CloudWatch, dashboard | `modules/monitoring` |
| Estado remoto y acceso de CI | S3 + OIDC de GitHub | `bootstrap/` |

## CI/CD (GitHub Actions)

| Evento | Workflow | Qué hace | Rol de AWS |
|---|---|---|---|
| Pull request a `main` | `terraform-plan` | `fmt`, `init`, `validate`, `plan` (resumen en la pestaña del job) | solo lectura |
| Merge a `main` | `terraform-apply` | `plan` + `apply` | solo la rama `main` |
| Manual | `terraform-destroy` | Borra todo; exige escribir `destroy` | solo la rama `main` |

El pipeline entra a AWS por OIDC: no hay llaves de acceso guardadas en GitHub.

## Observabilidad

Alarmas (todas notifican por SNS al correo configurado y avisan también al recuperarse):

- ALB: sin hosts sanos (2 min), más de 5% de errores 5xx (5 min), latencia promedio mayor a 3 s (5 min).
- ECS: CPU y memoria mayores a 85% (10 min).
- RDS: CPU mayor a 85% (10 min), más de 50 conexiones, menos de 2 GB libres.
- Valkey: CPU y memoria mayores a 85% (10 min).

El dashboard `a5iac-moodle-observabilidad` agrupa: resumen de alarmas, ALB, ECS con errores recientes de los logs, y RDS y Valkey. La URL sale en el output `dashboard_url`.

## Puesta en marcha (una sola vez)

Requisitos: Terraform >= 1.10 y credenciales de AWS locales.

1. **Bootstrap** (crea el bucket del estado y los roles de GitHub):
   ```bash
   cd bootstrap
   terraform init
   terraform apply
   terraform output
   ```
   Si la cuenta ya tiene el proveedor OIDC de GitHub, usa `-var create_oidc_provider=false`.
2. **Variables y secretos en GitHub** (Settings > Secrets and variables > Actions):

   | Tipo | Nombre | Valor |
   |---|---|---|
   | Variable | `TF_STATE_BUCKET` | output `tf_state_bucket` |
   | Variable | `AWS_PLAN_ROLE_ARN` | output `plan_role_arn` |
   | Variable | `AWS_APPLY_ROLE_ARN` | output `apply_role_arn` |
   | Variable | `ALERT_EMAIL` | correo para las alertas |
   | Secret | `DB_PASSWORD` | clave de RDS |
   | Secret | `MOODLE_ADMIN_PASSWORD` | clave del admin de Moodle |
3. **Protección de la rama** (recomendado): en Settings > Branches, exigir pull request y que pase `terraform-plan` antes de hacer merge a `main`.
4. Hacer un pull request a `main`: se ejecuta el plan. Al hacer merge se despliega.
5. **Confirmar la suscripción:** AWS envía un correo de confirmación de SNS. Las alertas no llegan hasta aceptarlo.

## Uso local (opcional)

```bash
cp backend.hcl.example backend.hcl            # poner el bucket
cp terraform.tfvars.example terraform.tfvars  # poner claves
terraform init -backend-config=backend.hcl
terraform plan
```

## Notas

- El rol de apply usa `AdministratorAccess`, y solo `main` puede asumirlo. En un entorno real se reemplaza por una política con los servicios exactos.
- Las claves llegan a la task definition como variables de entorno (quedan en el estado). Mejora pendiente: AWS Secrets Manager.
- No hay pipeline de aplicación: Moodle usa una imagen pública. Para uno propio haría falta un fork de Moodle con Dockerfile, un repositorio ECR y un workflow que construya y despliegue la imagen.
