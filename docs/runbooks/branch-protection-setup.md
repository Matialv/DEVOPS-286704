# Guía: Configuración de Branch Protection y GitHub Environments

Pasos de configuración en la GitHub UI para hacer cumplir la estrategia de ramas definida en el ADR 001.

---

## 1. Branch Protection Rules para `main`

Ir a: **GitHub repo → Settings → Branches → Add branch protection rule**

Nombre del patrón: `main`

Activar las siguientes opciones:

| Opción | Valor |
|--------|-------|
| Require a pull request before merging | ✓ |
| → Required approvals | **1** |
| → Dismiss stale pull request approvals when new commits are pushed | ✓ |
| Require status checks to pass before merging | ✓ |
| → Status checks requeridos | `secret-scan`, `sast`, `sca` |
| Require branches to be up to date before merging | ✓ |
| Do not allow bypassing the above settings | ✓ |
| Restrict who can push to matching branches | ✓ (solo admins) |

Guardar con **Create** / **Save changes**.

---

## 2. Configuración de GitHub Environments

Ir a: **GitHub repo → Settings → Environments**

### Environment `dev`

- **No requiere aprobadores** — el pipeline despliega automáticamente al hacer push a `main`.
- Deployment branch: `main`

### Environment `test`

- **No requiere aprobadores** — se activa via `workflow_dispatch`.
- Deployment branch: `main`

### Environment `prod`

Ir a: **Settings → Environments → New environment** → nombre: `prod`

| Configuración | Valor |
|--------------|-------|
| Required reviewers | Agregar usuarios/equipos aprobadores (ej. `Matialv15`) |
| Prevent self-review | ✓ (recomendado) |
| Deployment branch | `main` únicamente (`Selected branches` → agregar `main`) |
| Wait timer | Opcional (ej. 5 min para dar tiempo de cancelar) |

---

## 3. Variable `PROD_APPROVERS`

Los workflows referencian `${{ vars.PROD_APPROVERS }}` para el step de aprobación manual.

Ir a: **Settings → Environments → prod → Environment variables → Add variable**

| Nombre | Valor |
|--------|-------|
| `PROD_APPROVERS` | Lista de usuarios GitHub separados por coma (ej. `Matialv15`) |

---

## 4. Verificación

Una vez configurado, el flujo completo funciona así:

1. Crear rama `feature/xxx` desde `main`
2. Hacer cambios y push
3. Abrir Pull Request → los checks `secret-scan`, `sast`, `sca` deben pasar
4. Al menos 1 revisor aprueba → merge habilitado
5. Merge a `main` → `deploy.yml` se dispara automáticamente con `environment=dev`
6. Para promover a prod: `Actions → App Pipeline → Run workflow → environment: prod`
7. El job `build` pausa esperando aprobación en la pestaña **Environments** de GitHub
8. El aprobador listado en `PROD_APPROVERS` recibe notificación por email y aprueba desde la UI
9. El pipeline continúa: push a ECR → trigger de `infra.yml` con `environment=prod` → nueva aprobación en `terraform-apply`
