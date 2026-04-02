# Architecture finale — Projet CI/CD Zero Touch

## Vue d'ensemble

```markdown
┌─────────────────────────────────────────────────────────────┐
│                        GitHub Actions                        │
│             workflow_dispatch → deploy.yml                   │
│                                                              │
│  Job 1 ─ Build et Push images ──────────────────► GHCR       │
│  Job 2 ─ Terraform ────────────────────────────► EC2 App    │
│  Job 3 ─ Bridge (inventory.ini + key.pem)                    │
│  Job 4 ─ Ansible ──────────────────────────────► EC2 App    │
│        └─ Validation curl (frontend + API)                   │
└──────────────────┬───────────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
┌───────────────┐   ┌──────────────────────────┐
│  EC2 Registry │   │      EC2 Applicative      │
│ 51.44.184.112 │   │   IP dynamique Terraform  │
│               │   │                           │
│ Docker        │   │ Frontend  :3000 (public)  │
│ Registry :5000│   │ API       :8000 (public)  │
│ Registry UI:80│   │ MySQL     :3306 (interne) │
│ Auth htpasswd │   │ Adminer   :8080 (interne) │
└───────────────┘   └──────────────────────────┘
```

## EC2 Registry (TP4)

- **IP** : 51.44.184.112
- **Provisionnée par** : `infra/` (Terraform) + `config/` (Ansible)
- **Services** :
  - `registry:2` sur le port 5000 — stockage des images Docker
  - `joxit/docker-registry-ui` sur le port 80 — interface web
- **Authentification** : htpasswd (`admin` / secret dans GitHub Secrets)
- **Infrastructure** : EC2 t3.micro, Ubuntu 24.04, clé SSH statique

## EC2 Applicative

- **IP** : dynamique, générée à chaque `terraform apply`
- **Provisionnée par** : `infra/` (Terraform) — clé SSH générée à la volée
- **Configurée par** : `ansible/playbook.yml`
- **Services** :
  - Frontend React/Nginx — port 3000 (exposé publiquement)
  - API FastAPI — port 8000 (exposé publiquement)
  - MySQL — port 3306 (interne uniquement)
  - Adminer — port 8080 (interne uniquement)
- **Images** : récupérées depuis GHCR (`ghcr.io/<actor>/tp-cicd-*:latest`)

## Pipeline deploy.yml

| Job | Description |
| ----- | ------------- |
| **build-and-push** | Build des images api/frontend/mysql et push sur GHCR |
| **terraform** | `terraform apply` → crée l'EC2, expose IP + clé privée en output |
| **bridge** | Écrit `key.pem` + génère `inventory.ini` depuis les outputs Terraform |
| **ansible** | Installe Docker, login GHCR, déploie la stack, valide avec `curl` |

## Secrets GitHub requis

| Secret | Description |
| -------- | ------------- |
| `AWS_ACCESS_KEY_ID` | Clé d'accès IAM AWS |
| `AWS_SECRET_ACCESS_KEY` | Clé secrète IAM AWS |
| `MYSQL_ROOT_PASSWORD` | Mot de passe root MySQL |
| `MYSQL_DATABASE` | Nom de la base de données |
| `MYSQL_USER` | Utilisateur MySQL |

> `GITHUB_TOKEN` est fourni automatiquement par GitHub Actions.

## Structure du dépôt

```markdown
infra/                        → Terraform (EC2 applicative)
config/                       → Ansible (EC2 registry)
ansible/
  playbook.yml                → Playbook déploiement app
  templates/
    docker-compose.prod.yml.j2 → Stack prod (images GHCR)
.github/
  workflows/
    deploy.yml                → Pipeline Zero Touch
    build_test_react.yml      → CI tests
app/                          → Frontend React/Vite
api/                          → Backend FastAPI
mysql/                        → Init SQL
```
