# Guía de Comandos para la Demo de Clase

Este documento contiene los comandos exactos y el paso a paso para la demostración en vivo de la solución de infraestructura, observabilidad y CI/CD.

---

## 1. Variables de Entorno Previas

Define la URL de Moodle (obtenida del output `moodle_url` de Terraform en el resumen del job de apply):

```bash
export MOODLE_URL="http://http://a5iac-moodle-alb-1029717847.us-east-1.elb.amazonaws.com"
export AWS_REGION="us-east-1"
```

---

## 2. Pruebas de Carga y Sobrecarga con `curl`

### A. Prueba de humo / ligera (validar disponibilidad)
Envía 1.000 peticiones con 20 hilos en paralelo al endpoint de login (que golpea PHP, MySQL y Redis/Valkey):
```bash
seq 1 1000 | xargs -P 20 -I{} curl -s -o /dev/null -w "%{http_code}\n" "$MOODLE_URL/login/index.php" | sort | uniq -c
```
*Resultado esperado:* La gran mayoría o el 100% de códigos `200`.

### B. Sobrecarga intensa (estresar Fargate y ALB)
Envía 20.000 peticiones con 100 procesos concurrentes:
```bash
seq 1 20000 | xargs -P 100 -I{} curl -s -o /dev/null -w "%{http_code}\n" "$MOODLE_URL/login/index.php" | sort | uniq -c
```
*Resultado esperado:* Verás aparecer códigos `502`, `503` o `504` conforme la cola del ALB se satura y la CPU de la tarea de ECS se dispara hacia el 100%.

---

## 3. Inspección de Logs en Vivo

Para proyectar en la terminal mientras se ejecuta la prueba de carga:
```bash
aws logs tail /ecs/a5iac-moodle --follow
```
*(Para ver solo líneas con advertencias o errores)*:
```bash
aws logs tail /ecs/a5iac-moodle --follow --filter-pattern "error"
```

---

## 4. Demostración Rápida de Notificaciones SNS (Alertas por Correo)

Las alarmas reales de producción exigen evaluar condiciones durante 5 a 10 minutos para evitar falsos positivos por picos transitorios. Para demostrar el canal de notificación por correo **al instante**:

### Forzar estado de alarma:
```bash
aws cloudwatch set-alarm-state \
  --alarm-name a5iac-moodle-ecs-cpu-alta \
  --state-value ALARM \
  --state-reason "Demo en clase: prueba de notificaciones SNS"
```
*Acción esperada:* Llega de inmediato un correo de AWS Notifications a `castaxyz@gmail.com` indicando estado `ALARM`.

### Restaurar estado normal (OK):
```bash
aws cloudwatch set-alarm-state \
  --alarm-name a5iac-moodle-ecs-cpu-alta \
  --state-value OK \
  --state-reason "Demo en clase: recuperacion del servicio"
```
*Acción esperada:* Llega el correo de recuperación indicando estado `OK`.

---

## 5. Simulación de Caída de Servicio (Uptime / Healthy Hosts)

Para mostrar cómo reacciona la alarma `a5iac-moodle-sin-hosts-sanos` (evalúa cada 1 min, dispara a los 2 min):

### Bajar contenedores a 0:
```bash
aws ecs update-service \
  --cluster a5iac-moodle-cluster \
  --service a5iac-moodle-service \
  --desired-count 0
```

### Restaurar contenedores a 1:
```bash
aws ecs update-service \
  --cluster a5iac-moodle-cluster \
  --service a5iac-moodle-service \
  --desired-count 1
```

---

## 6. Monitoreo y Dashboard

- Abre la consola de AWS CloudWatch en:
  **CloudWatch > Dashboards > `a5iac-moodle-observabilidad`**
- Secciones para señalar al profesor:
  1. **Resumen de incidentes:** widget con el estado de las 10 alarmas.
  2. **Frontend (ALB):** tráfico total, errores 5xx (sumando Target y ELB), latencia y hosts sanos.
  3. **Backend (ECS Fargate):** porcentaje de CPU y memoria, y widget de CloudWatch Logs Insights mostrando errores recientes de Moodle.
  4. **Persistencia (RDS & Valkey):** conexiones activas, CPU y disco libre en base de datos; CPU y memoria del motor en memoria.

---

## 7. Destrucción de Recursos (Post-Demo)

Para no generar costos en la cuenta personal una vez calificada la actividad:
1. Ir a **GitHub > Actions > `terraform-destroy`**.
2. Hacer clic en **Run workflow**.
3. Escribir `destroy` en el campo de confirmación y ejecutar.

---

## 8. Hallazgos Importantes y Decisiones Técnicas

1. **Filtrado de rutas (`paths`) en el Pipeline de Apply:**
   - Hacer push a `main` de archivos que no sean de Terraform (como este `DEMO.md` o documentación) **no reinicia ni dispara el aprovisionamiento**. El workflow `terraform-apply.yml` contiene la regla `paths: ["**.tf", ".terraform.lock.hcl"]`, garantizando que cambios en la documentación no consuman minutos de CI ni toquen la infraestructura.

2. **Idempotencia de Terraform:**
   - Incluso si se gatillara un `apply` manualmente o tras un merge sin cambios de infraestructura, Terraform solo lee el estado remoto en S3 y confirma que la infraestructura real coincide (`No changes`). No destruye ni recrea recursos a menos que su definición cambie.

3. **Mecanismo de Despliegue (Merge vs Direct Push):**
   - El despliegue a producción en AWS está estrictamente protegido:
     - En **Pull Requests**: se asume el rol con permisos de solo lectura (`a5iac-moodle-gha-plan`) y únicamente se ejecuta `terraform plan`.
     - En **Merge a `main`**: se asume el rol con permisos administrativos (`a5iac-moodle-gha-apply`) y se ejecuta `terraform apply`.
     - Ninguna rama fuera de `main` puede modificar los recursos de AWS.

4. **Identificador OIDC con soporte numérico (`StringLike`):**
   - Durante la integración se descubrió que GitHub Actions envía el claim `sub` con los IDs numéricos de usuario y repositorio (`repo:Franyelica@99375805/actividad5_iac@1455887183:*`). La política de confianza en AWS IAM requirió el uso del operador `StringLike` con comodines (`repo:Franyelica*/actividad5_iac*:*`) en lugar de `StringEquals` para admitir de manera transparente ambos formatos de token sin comprometer la seguridad.

5. **Métrica 5xx completa (Target + ALB):**
   - Bajo cargas masivas o fallos del contenedor, el Application Load Balancer genera errores `502 Bad Gateway`, `503 Service Unavailable` o `504 Gateway Timeout` directamente en el balanceador (`HTTPCode_ELB_5XX_Count`), adicionales a los que pueda generar el propio Moodle (`HTTPCode_Target_5XX_Count`). La alarma de observabilidad y el dashboard suman ambas métricas para garantizar que ninguna falla pase desapercibida.

6. **Entorno de Ejecución de Terraform (Nube vs Local):**
   - El despliegue de la infraestructura productiva no se ejecuta en la máquina del desarrollador, sino en un runner efímero de **GitHub Actions**:
     1. **Runner de GitHub Actions:** Se levantó automáticamente cuando se hizo el merge del PR a la rama `main`.
     2. **Autenticación OIDC:** Usó el rol IAM `arn:aws:iam::193793987836:role/a5iac-moodle-gha-apply` (creado en el bootstrap) para conectarse de forma segura a la cuenta personal de AWS sin almacenar llaves de acceso estáticas.
     3. **Estado Remoto:** Descargó y bloqueó con lockfile el archivo de estado directamente en el bucket S3 `a5iac-moodle-tfstate-193793987836`.
     4. **Creación de recursos:** Fue el runner de GitHub el que llamó a las APIs de AWS para aprovisionar la VPC, el balanceador ALB, la base de datos RDS MySQL, el cluster de ECS y el monitoreo.
   - En la máquina local únicamente se ejecutó el **bootstrap** una sola vez (para crear el bucket S3 y los roles IAM) y los comandos de Git / inspección de AWS CLI.

