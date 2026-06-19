# ADR 001: Estrategia de ramas - GitHub Flow

## Estado
Aceptado

## Contexto
Se necesita una estrategia de ramificación clara para el equipo.

## Decisión
Se adopta **GitHub Flow** adaptado: `main` + `feature/*` + `hotfix/*`.

## Justificación
- Simplicidad operativa para un equipo pequeño
- Integración directa con GitHub Actions
- Branch protection rules sobre `main`

## Consecuencias
- No merge a `main` sin PR y aprobación de al menos 1 revisor
- Todo push a `main` dispara el pipeline de dev
