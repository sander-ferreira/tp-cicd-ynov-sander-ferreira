# Architecture finale — Projet CI/CD Zero Touch

## Vue d'ensemble

```markdown
┌─────────────────────────────────────────────────────────────┐
│                        GitHub Actions                        │
│             workflow_dispatch → deploy.yml                   │
│                                                              │
│  Job 1 ─ Build et Push API + MySQL ─────────────────────┐   │
│  Job 2 ─ Terraform ──────────────────────► EC2 App      │   │
│  Job 3 ─ Ansible :                                       │   │
│           ├─ Build Frontend (VITE_API_URL=IP Terraform)  │   │
│           ├─ Push Frontend ─────────────────────────────►│   │
│           ├─ Deploy stack sur EC2                        │   │
│           └─ Validation curl (frontend + API)            │   │
│                                                          ▼   │
│                                          Registry AWS privé  │
└──────────────────┬───────────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
┌────────────────────┐   ┌──────────────────────────┐
│   EC2 Registry     │   │      EC2 Applicative      │
│   13.38.94.10      │   │   IP dynamique Terraform  │
│                    │   │                           │
│ Nginx :443 (HTTPS) │   │ Frontend  :3000 (public)  │
│  ├─ /v2/* → API    │   │ API       :8000 (public)  │
│  └─ /*    → UI     │   │ MySQL     :3306 (interne) │
│ Nginx :80 → 301    │   │ Adminer   :8080 (interne) │
│ Auth htpasswd      │   │                           │
└────────────────────┘   └──────────────────────────┘
```

## EC2 Registry

- **IP** : 13.38.94.10
- **Provisionnée par** : `infra-registry/` (Terraform) + `registry/` (Ansible)
- **Services** :
  - `registry:2` — stockage des images Docker (interne, port 5000)
  - `nginx` — reverse proxy HTTPS sur port 443 (certif SSL self-signed) avec routing par path : `/v2/*` → API Docker, `/*` → UI web. Le port 80 redirige vers 443.
  - `joxit/docker-registry-ui` — interface web (interne, port 80)
- **Authentification** : htpasswd (`admin` / secret dans GitHub Secrets)
- **Infrastructure** : EC2 t3.micro, Ubuntu 24.04, clé SSH générée par Terraform

## EC2 Applicative

- **IP** : dynamique, générée à chaque `terraform apply`
- **Provisionnée par** : `infra/` (Terraform) — clé SSH générée à la volée
- **Configurée par** : `ansible/playbook.yml`
- **Services** :
  - Frontend React/Nginx — port 3000 (exposé publiquement)
  - API FastAPI — port 8000 (exposé publiquement)
  - MySQL — port 3306 (interne uniquement)
  - Adminer — port 8080 (interne uniquement)
- **Images** : récupérées depuis le registry privé AWS (`13.38.94.10:443`)

## Pipeline deploy.yml

| Job | Description |
| ----- | ------------- |
| **docker-build-and-deploy** | Build et push API + MySQL vers le registry privé AWS |
| **terraform** | `terraform apply` → crée l'EC2 app, expose IP + clé privée |
| **ansible** | Build frontend avec IP connue, push, déploie la stack, valide avec `curl` |

## Secrets GitHub requis

| Secret | Description |
| -------- | ------------- |
| `AWS_ACCESS_KEY_ID` | Clé d'accès IAM AWS |
| `AWS_SECRET_ACCESS_KEY` | Clé secrète IAM AWS |
| `PRIVATE_REGISTRY_PUBLIC_IP` | IP:port du registry privé AWS (`13.38.94.10:443`) |
| `PRIVATE_REGISTRY_USERNAME` | Utilisateur du registry (`admin`) |
| `PRIVATE_REGISTRY_PASSWORD` | Mot de passe du registry |
| `REGISTRY_CERT` | Certificat SSL self-signed du registry |
| `MYSQL_ROOT_PASSWORD` | Mot de passe root MySQL |
| `MYSQL_DATABASE` | Nom de la base de données |
| `MYSQL_USER` | Utilisateur MySQL |

## Structure du dépôt

```markdown
infra/                          → Terraform (EC2 applicative, éphémère)
infra-registry/                 → Terraform (EC2 registry, permanent)
registry/                       → Ansible (déploiement registry Docker privé)
  deploy.yml
  inventory.ini
  templates/
    docker-compose.yml          → Stack registry (nginx + registry + UI)
    nginx.conf.j2               → Config reverse proxy HTTPS
ansible/                        → Ansible (déploiement stack applicative)
  playbook.yml
  templates/
    docker-compose.prod.yml.j2  → Stack prod (images registry privé)
.github/
  workflows/
    deploy.yml                  → Pipeline Zero Touch
    build_test_react.yml        → CI tests
app/                            → Frontend React/Vite
api/                            → Backend FastAPI
mysql/                          → Init SQL
```
