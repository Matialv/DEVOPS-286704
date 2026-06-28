# DEVOPS-286704
Obligatorio de DEVOPS ATI / ORT 2026

# RetailStore — Plataforma de E-Commerce DevSecOps en AWS

**RetailStore** es una plataforma de comercio electrónico basada en **microservicios**, desplegada en AWS mediante una pipeline CI/CD completa con seguridad integrada (DevSecOps). Este documento describe la arquitectura de la aplicación, la infraestructura en AWS, las condiciones de deploy y el funcionamiento de los pipelines de GitHub Actions.

---

## Tabla de Contenidos

1. [Arquitectura General](#arquitectura-general)
2. [Microservicios](#microservicios)
3. [Infraestructura AWS](#infraestructura-aws)
4. [Módulos Terraform](#módulos-terraform)
5. [Pipelines CI/CD — GitHub Actions](#pipelines-cicd--github-actions)
6. [Condiciones de Deploy](#condiciones-de-deploy)
7. [Seguridad Integrada](#seguridad-integrada)
8. [Observabilidad y Monitoreo](#observabilidad-y-monitoreo)
9. [Entornos y Configuración](#entornos-y-configuración)
10. [Ejecución Local](#ejecución-local)
11. [Estructura del Repositorio](#estructura-del-repositorio)

---

## Arquitectura General

RetailStore se despliega en tres entornos independientes (`dev`, `test`, `prod`), cada uno con su propia VPC, cluster ECS, RDS y Redis. El tráfico entra por un **Application Load Balancer (ALB)** que enruta a los servicios Fargate en subredes privadas.

```
Internet
    │
    ▼
┌───────────────────────────────────────────────────────────────────────┐
│  AWS  ·  VPC (por entorno)                                            │
│                                                                       │
│  ┌──────────────────┐   Subredes Públicas                             │
│  │  ALB             │◄──────────────────────── HTTPS :80              │
│  │  (puerto 80,     │   :8001 :8002 :8003                             │
│  │  8001-8004,3001) │   :8004 :3001                                   │
│  └────────┬─────────┘                                                 │
│           │ Target Groups                                             │
│  ─────────────────────────────────── Subredes Privadas ────────────── │
│           │                                                           │
│  ┌────────▼─────────────────────────────────────────────────────┐    │
│  │  ECS Cluster (Fargate)                                        │    │
│  │                                                               │    │
│  │  ┌──────┐ ┌──────┐ ┌──────────┐ ┌──────┐ ┌────┐ ┌───────┐  │    │
│  │  │  ui  │ │catal.│ │  cart    │ │check.│ │ord.│ │admin  │  │    │
│  │  │:3000 │ │:8080 │ │ :8002    │ │:8003 │ │:80 │ │:3001  │  │    │
│  │  └──────┘ └──┬───┘ └────┬─────┘ └──┬───┘ └──┬─┘ └───┬───┘  │    │
│  └─────────────────────────────────────────────────────────────┘    │
│              │         │          │        │       │                  │
│         ┌────▼─────────▼──────────▼────────▼───────▼────────┐       │
│         │  RDS PostgreSQL 16 (subredes privadas)             │       │
│         │  Secret: retailstore/{env}/db-credentials          │       │
│         └────────────────────────────────────────────────────┘       │
│                                                                       │
│         ┌──────────────────────────────────┐                         │
│         │  ElastiCache Redis 7 (checkout)  │                         │
│         └──────────────────────────────────┘                         │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  ECR  ─  6 repositorios (catalog, cart, checkout, orders,       │ │
│  │          ui, admin)  ·  imagen: {env}-{commit-sha}              │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  ┌──────────────────┐  ┌─────────────────────────────────────────┐   │
│  │  Lambda          │  │  CloudWatch                             │   │
│  │  ecr-scan-       │  │  Dashboard · Alarms · Log Groups        │   │
│  │  notifier        │  │  SNS → Email (matialv15@gmail.com)      │   │
│  └──────┬───────────┘  └─────────────────────────────────────────┘   │
│         │ EventBridge (ECR scan complete)                            │
│         └─────────────────────────────────────────────────────────── │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Microservicios

| Servicio   | Tecnología            | Puerto externo | Puerto interno | Base de datos        |
|------------|-----------------------|:--------------:|:--------------:|----------------------|
| **ui**     | Node.js 22 + Express  | 80             | 3000           | Ninguna (stateless)  |
| **catalog**| Go 1.25 + Gin + GORM  | 8001           | 8080           | PostgreSQL           |
| **cart**   | Python 3.13 + FastAPI | 8002           | 8002           | PostgreSQL           |
| **checkout**| TypeScript + NestJS  | 8003           | 8003           | Redis (sesiones)     |
| **orders** | Go 1.25 + Gin + GORM  | 8004           | 8080           | PostgreSQL           |
| **admin**  | Node.js 22 + Express  | 3001           | 3001           | PostgreSQL (directo) |

### Flujo de comunicación

```
Navegador
    │
    ▼ :80
   ui  ──► catalog (:8001)
       ──► cart    (:8002)
       ──► checkout(:8003) ──► orders (:8004)
       ──► orders  (:8004)

   admin (:3001) ──► PostgreSQL (conexión directa SSL)
```

### Dockerfiles

Todos los servicios implementan:
- **Builds multi-etapa** (separación build/runtime)
- **Usuario no-root** (`nonroot` en Go/distroless, `appuser` en Node/Python)
- **Imágenes mínimas**: distroless (Go), alpine (Node 22, Python 3.13-slim)
- **Sin credenciales embebidas**
- Tamaño máximo validado: **500 MB**

---

## Infraestructura AWS

### Servicios utilizados y su relación

| Servicio AWS           | Rol en la arquitectura                                                                 |
|------------------------|----------------------------------------------------------------------------------------|
| **VPC**                | Red privada por entorno (CIDRs: dev=10.0/16, test=10.1/16, prod=10.2/16)             |
| **Subredes públicas**  | ALB expuesto a internet (2 AZs)                                                        |
| **Subredes privadas**  | ECS Fargate, RDS, ElastiCache — sin acceso público directo                            |
| **NAT Gateway**        | Salida a internet desde subredes privadas (ECS → ECR, Secrets Manager)               |
| **Security Groups**    | ALB (80/443/8001-8004/3001), ECS (solo desde ALB), RDS (5432 solo desde ECS), Redis  |
| **ALB**                | Enrutamiento por puerto a target groups de ECS; health checks /health                |
| **ECS (Fargate)**      | Cluster de contenedores sin servidores: 1 instancia dev/test, 2 instancias en prod   |
| **ECR**                | 6 repositorios de imágenes (uno por servicio), scan automático, tags inmutables      |
| **RDS PostgreSQL 16**  | Base de datos relacional en subredes privadas; Multi-AZ solo en prod                 |
| **ElastiCache Redis 7**| Cache de sesiones para Checkout; nodo único por entorno                              |
| **Secrets Manager**    | Credenciales DB en `retailstore/{env}/db-credentials` (JSON con host/port/user/pass) |
| **S3**                 | Backend remoto de estado Terraform (cifrado, versionado)                              |
| **DynamoDB**           | Lock de estado Terraform (evita applies concurrentes)                                 |
| **Lambda**             | Función `ecr-scan-notifier` (Python 3.12) — notifica críticos de ECR via SNS        |
| **EventBridge**        | Dispara Lambda cuando finaliza un scan de imagen ECR                                 |
| **SNS**                | Topic `retailstore-{env}-security-alerts` → suscripción email                        |
| **CloudWatch**         | Dashboard operacional, Log Groups por servicio, 4 tipos de alarmas                   |
| **IAM (LabRole)**      | Rol de ejecución para ECS tasks y Lambda (AWS Academy)                               |

---

## Módulos Terraform

La infraestructura se organiza en **7 módulos reutilizables** bajo `infrastructure/modules/`:

### `networking`
Crea la red base de cada entorno:
- VPC + Internet Gateway
- 2 subredes públicas y 2 privadas (multi-AZ)
- NAT Gateway (una AZ, optimización de costo)
- Tablas de rutas (pública → IGW, privada → NAT)
- 4 Security Groups: ALB, ECS, RDS, Redis

### `ecr`
Crea los repositorios de imágenes:
- 6 repos `retailstore-{env}-{service}`
- Scan automático al push, tags inmutables, cifrado AES256
- Lifecycle policy: retiene solo las últimas N imágenes

### `rds`
Crea la base de datos relacional:
- PostgreSQL 16, subredes privadas, sin acceso público
- DB Subnet Group en subredes privadas
- Tamaños por entorno: `db.t3.micro` (dev) → `db.t3.small` (test) → `db.t3.medium` (prod)
- Multi-AZ y deletion protection solo en prod
- Integración con Secrets Manager: lee credenciales del secret preexistente

### `elasticache`
Crea el cluster Redis para el servicio Checkout:
- Redis 7.1, puerto 6379, subredes privadas
- Tamaños: `cache.t3.micro` → `cache.t3.small` → `cache.t3.medium`

### `ecs`
Módulo principal de cómputo — crea todo el stack de contenedores:
- **ECS Cluster** con Container Insights habilitado
- **Task Definitions** (Fargate, awsvpc) con:
  - Variables de entorno por servicio (endpoints, puertos, DB config)
  - Secretos inyectados desde Secrets Manager (password)
  - SSL requerido en conexiones PostgreSQL (`sslmode=require`)
  - Logging a CloudWatch (`/retailstore/{env}/{service}`)
- **Application Load Balancer** con listener :80 → ui y listeners adicionales para cada servicio
- **Target Groups** con health checks en `/health` (30s interval, HTTP 200)
- **ECS Services** (Fargate): 1 instancia dev/test, 2 en prod, subredes privadas, sin IP pública

### `lambda`
Automatización de seguridad serverless:
- SNS Topic `retailstore-{env}-security-alerts` + suscripción email
- Lambda `ecr-scan-notifier` (Python 3.12, 30s timeout)
- EventBridge Rule: ECR Scan Complete → Lambda → SNS si hay CVEs CRITICAL
- Mensaje incluye conteo por severidad, pasos de remediación y link a ECR

### `observability`
Monitoreo y alertas:
- **CloudWatch Dashboard** `RetailStore-{env}`:
  - CPU y memoria ECS por servicio (timeseries 5 min)
  - Request count ALB + tasa de errores 4xx/5xx
  - Latencia ALB p99 (1 min)
  - Hosts saludables/no saludables (single value)
- **4 CloudWatch Alarms** (todas publican a SNS):
  1. `alb_5xx_errors` — más de 10 errores 5xx en 5 minutos
  2. `ecs_cpu_high` — CPU > 80% por 10 minutos (una alarma por servicio)
  3. `alb_latency_high` — p99 latencia > 2 segundos
  4. `unhealthy_hosts` — algún host no saludable detectado

### Composición por entorno

Cada entorno tiene su propio directorio `infrastructure/environments/{env}/` con:
- `main.tf` — instancia los 7 módulos con parámetros del entorno
- `variables.tf` + `{env}.tfvars` — overrides de instancias, CIDRs, Multi-AZ, etc.
- `outputs.tf` — expone ALB DNS, RDS endpoint, secret ARN
- Backend S3 independiente por entorno (estado aislado)

---

## Pipelines CI/CD — GitHub Actions

Dos workflows coordinados automatizan el ciclo completo de entrega:

### `deploy.yml` — Build, Scan y Push de Imágenes

**Disparadores**: Push a `main`, `main-test`, o `main-prod`; también `workflow_dispatch` manual.

**Detección de entorno**: El pipeline lee el nombre del branch para seleccionar el entorno:
- `main` → `dev`
- `main-test` → `test`
- `main-prod` → `prod`

```
┌─────────────────────────────────────────────────────────────────────┐
│  deploy.yml                                                          │
│                                                                      │
│  [1] detect-env     Detecta entorno según branch                    │
│                                                                      │
│  [2] gitleaks       Escaneo de secretos hardcodeados                │
│        └── BLOQUEA si encuentra credenciales en el código           │
│                                                                      │
│  [3] sast           Semgrep (Go, Python, TypeScript, OWASP Top 10) │
│        └── BLOQUEA si encuentra vulnerabilidades CRITICAL/HIGH       │
│                                                                      │
│  [4] sca            Trivy filesystem scan (dependencias)            │
│        └── BLOQUEA en severidad CRITICAL                            │
│                                                                      │
│  [5] approve-prod   Approval gate GitHub Environment (solo prod)    │
│        └── Requiere aprobación manual en GitHub                     │
│                                                                      │
│  [6] bootstrap-ecr  Terraform apply — crea repositorios ECR        │
│                                                                      │
│  [7] build          Matrix 6 servicios en paralelo:                 │
│        ├── Hadolint (lint Dockerfile)                               │
│        ├── docker build --tag {env}-{sha}                           │
│        ├── Trivy image scan → BLOQUEA en CRITICAL                   │
│        ├── Validación metadata (non-root + tamaño < 500MB)          │
│        ├── Gitleaks en capas de la imagen                           │
│        └── docker push → ECR                                        │
│                                                                      │
│  [8] update-tfvars  Actualiza image_tag en {env}.tfvars             │
│        └── git push origin HEAD:{branch}                            │
│        └── gh workflow run infra.yml --ref {branch}                 │
└─────────────────────────────────────────────────────────────────────┘
```

### `infra.yml` — Despliegue de Infraestructura Terraform

**Disparadores**: Cambios en `infrastructure/**` o invocado por `deploy.yml` via `gh workflow run`.

```
┌─────────────────────────────────────────────────────────────────────┐
│  infra.yml                                                           │
│                                                                      │
│  [1] detect-env     Detecta entorno según branch/input              │
│                                                                      │
│  [2] terraform-init Init + validate (backend S3)                    │
│                                                                      │
│  [3] bootstrap-secrets  Crea secret en Secrets Manager              │
│        └── retailstore/{env}/db-credentials (si no existe)          │
│                                                                      │
│  [4] terraform-plan Empaqueta Lambda ZIP + terraform plan           │
│        └── Sube tfplan como artifact                                │
│                                                                      │
│  [5] approve-prod   Approval gate (solo prod)                       │
│                                                                      │
│  [6] terraform-apply Descarga artifact + terraform apply            │
│        └── Extrae ALB DNS y RDS endpoint                            │
│        └── Actualiza Secrets Manager con endpoint real de RDS       │
│                                                                      │
│  [7] smoke-tests    Espera servicios healthy → tests de integración │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Condiciones de Deploy

### Gates de seguridad (bloquean el pipeline)

Todas las etapas siguientes deben pasar **antes** de que cualquier imagen llegue a ECR o se despliegue infraestructura:

| Gate | Herramienta | Qué verifica | Criterio de bloqueo |
|------|-------------|--------------|---------------------|
| Secret Detection | **Gitleaks** | Secretos en código fuente | Cualquier match |
| SAST | **Semgrep** | Vulnerabilidades en código (Go, Python, TS) | CRITICAL / HIGH |
| SCA | **Trivy fs** | Vulnerabilidades en dependencias | CRITICAL |
| Image Scan | **Trivy image** | CVEs en la imagen de contenedor | CRITICAL |
| Non-root | Bash script | El contenedor NO corre como root | `USER` ausente o `root` |
| Tamaño imagen | Bash script | Imagen menor a 500 MB | Supera límite |
| Lint Dockerfile | **Hadolint** | Buenas prácticas en Dockerfile | Warnings (no bloqueante) |

### Condiciones por entorno

| Entorno | Branch     | Aprobación manual | Multi-AZ | Instancias ECS | DB               |
|---------|------------|:-----------------:|:--------:|:--------------:|------------------|
| dev     | `main`     | No                | No       | 1              | db.t3.micro      |
| test    | `main-test`| No                | No       | 1              | db.t3.small      |
| prod    | `main-prod`| **Sí** (GitHub Environment) | **Sí** | 2  | db.t3.medium     |

### Flujo completo de promoción a producción

```
feature branch
     │
     ▼ PR + merge
   main  ──► deploy.yml (dev) ──► ECR dev-{sha} ──► ECS dev
     │
     ▼ PR + merge
 main-test ──► deploy.yml (test) ──► ECR test-{sha} ──► ECS test
     │
     ▼ PR + merge + aprobación manual
 main-prod ──► deploy.yml (prod)
               │
               ├── [approve-prod gate] ← requiere aprobador en GitHub
               │
               ▼
              ECR prod-{sha} ──► ECS prod
```

### Actualización automática de imagen

Cuando una imagen es empujada exitosamente a ECR, `deploy.yml` actualiza automáticamente el campo `image_tag` en el archivo `{env}.tfvars` correspondiente y dispara `infra.yml` para que Terraform aplique el nuevo tag en las task definitions de ECS, sin intervención manual.

---

## Seguridad Integrada

### Gestión de secretos

- **Ningún secreto en código fuente**. Credenciales solo en AWS Secrets Manager.
- Secret path: `retailstore/{env}/db-credentials`
- Estructura JSON: `{ username, password, host, port, dbname }`
- ECS inyecta el password como variable de entorno via `secrets` en la task definition
- **SSL obligatorio** en todas las conexiones a PostgreSQL (`sslmode=require`)

### Configuraciones de escaneo

| Archivo | Herramienta | Propósito |
|---------|-------------|-----------|
| `security/.gitleaks.toml` | Gitleaks | Reglas de detección de secretos (extiende defaults, permite `.env.example`) |
| `security/trivy.yaml` | Trivy | Severidad CRITICAL, exit-code 1 |
| `security/.trivyignore` | Trivy | CVEs documentados como excepciones con justificación |
| `security/semgrep.yml` | Semgrep | Reglas custom de secretos hardcodeados por lenguaje (Go, Python, TS) |

### Lambda de seguridad continua

La función `ecr-scan-notifier` se activa cada vez que ECR termina de escanear una imagen (EventBridge). Si encuentra vulnerabilidades CRITICAL, publica una alerta formateada a SNS con:
- Conteo de vulnerabilidades por severidad
- Pasos de remediación sugeridos
- Link directo a ECR Console

---

## Observabilidad y Monitoreo

### CloudWatch Dashboard (`RetailStore-{env}`)

- CPU y memoria ECS por cada uno de los 6 servicios (series temporales, 5 min)
- Request count ALB + tasa de errores 4xx y 5xx
- Latencia ALB percentil 99 (1 min)
- Hosts saludables vs no saludables (valor instantáneo)

### Alarmas CloudWatch

| Alarma | Condición | Acción |
|--------|-----------|--------|
| `alb_5xx_errors` | > 10 errores 5xx en 5 minutos | SNS → Email |
| `ecs_cpu_high` | CPU > 80% por 10 minutos (por servicio) | SNS → Email |
| `alb_latency_high` | Latencia p99 > 2 segundos | SNS → Email |
| `unhealthy_hosts` | > 0 hosts no saludables | SNS → Email |

### Logs

- Un Log Group por servicio: `/retailstore/{env}/{service}`
- Retención: 30 días (dev/test), 90 días (prod)
- Driver: `awslogs` en task definitions ECS

---

## Entornos y Configuración

### Variables por entorno (`{env}.tfvars`)

| Variable           | dev           | test           | prod           |
|--------------------|---------------|----------------|----------------|
| `vpc_cidr`         | 10.0.0.0/16   | 10.1.0.0/16    | 10.2.0.0/16    |
| `rds_instance_class`| db.t3.micro  | db.t3.small    | db.t3.medium   |
| `multi_az`         | false         | false          | true           |
| `redis_node_type`  | cache.t3.micro| cache.t3.small | cache.t3.medium|
| `ecs_desired_count`| 1             | 1              | 2              |
| `image_tag`        | dev-{sha}     | test-{sha}     | prod-{sha}     |

### Backend Terraform (estado remoto)

- **S3** con cifrado AES256 y versionado — un bucket por entorno
- **DynamoDB** como lock de estado (evita applies simultáneos)
- Terraform versión: **1.9.0**

---

## Ejecución Local

### Requisitos
- Docker 24+ y Docker Compose v2.20+

### Inicio rápido

```bash
git clone https://github.com/Matialv/RetailStore.git
cd RetailStore
docker compose up --build
```

| URL | Servicio |
|-----|---------|
| http://localhost:8080 | Tienda (UI) |
| http://localhost:8081 | Panel Admin |

### Comandos útiles

```bash
# Detener servicios
docker compose down

# Detener y limpiar base de datos
docker compose down -v

# Ver logs de un servicio
docker compose logs -f catalog

# Reconstruir un servicio
docker compose up --build cart
```

---

## Estructura del Repositorio

```
DEVOPS-286704/
├── .github/workflows/
│   ├── deploy.yml              # Build · SAST/SCA/secret scan · Push ECR
│   └── infra.yml               # Terraform plan/apply · smoke tests
│
├── infrastructure/
│   ├── modules/
│   │   ├── networking/         # VPC, subredes, NAT, security groups
│   │   ├── ecr/                # Repositorios de imágenes por servicio
│   │   ├── ecs/                # Cluster, task defs, ALB, services
│   │   ├── rds/                # PostgreSQL 16 + Secrets Manager
│   │   ├── elasticache/        # Redis 7 para checkout
│   │   ├── lambda/             # ecr-scan-notifier + EventBridge + SNS
│   │   └── observability/      # Dashboard + alarmas CloudWatch
│   │
│   └── environments/
│       ├── dev/   (main.tf · variables.tf · outputs.tf · dev.tfvars)
│       ├── test/  (main.tf · variables.tf · outputs.tf · test.tfvars)
│       └── prod/  (main.tf · variables.tf · outputs.tf · prod.tfvars)
│
├── src/
│   ├── ui/Dockerfile           # Node 22 alpine, 3 etapas, :3000
│   ├── catalog/Dockerfile      # Go 1.25 → distroless, :8080
│   ├── cart/Dockerfile         # Python 3.13-slim, :8002
│   ├── checkout/Dockerfile     # Node 22 + NestJS, :8003
│   ├── orders/Dockerfile       # Go 1.25 → distroless, :8080
│   └── admin/Dockerfile        # Node 22 alpine, :3001
│
├── security/
│   ├── .gitleaks.toml          # Reglas detección de secretos
│   ├── .trivyignore            # CVEs documentados como excepciones
│   ├── trivy.yaml              # Config Trivy (CRITICAL, exit-code 1)
│   └── semgrep.yml             # Reglas SAST custom por lenguaje
│
├── tests/
│   ├── wait-for-services.sh    # Polling de salud (120s timeout)
│   └── smoke-tests.sh          # Tests de integración básicos
│
├── docker-compose.yml          # Orquestación local (desarrollo)
└── README.md                   # Este archivo
```

---

## Notas de Arquitectura

- **Redes aisladas**: ECS no tiene IP pública; todo el tráfico entra por el ALB en subredes públicas
- **Secretos nunca en código**: Credenciales DB solo en Secrets Manager, inyectadas en runtime por ECS
- **SSL forzado**: Todas las conexiones a RDS usan `sslmode=require` (Go: `sslmode=require`, Python: `sslmode=require`, TypeScript: `ssl: { rejectUnauthorized: false }`)
- **Single database**: RDS tiene una única base de datos `retailstore`; catalog, cart, orders y admin conectan al mismo endpoint usando el mismo secret
- **Logs retención diferenciada**: Dev/test 30 días, prod 90 días para cumplimiento y costos
- **Lambda seguridad**: Serverless para alertas de CVEs — no requiere infraestructura adicional permanente

---

**Última actualización**: Junio 2026
