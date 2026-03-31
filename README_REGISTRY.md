# Déploiement d'un Registre Docker Privé sur AWS

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.2
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
- [AWS CLI](https://aws.amazon.com/cli/) configuré (`aws configure`)
- Docker Desktop avec `insecure-registries` configuré (voir étape 4)

## Structure

```markdown
infra/          → Code Terraform (EC2, Security Group, Key Pair)
config/         → Playbook Ansible + templates Docker Compose
```

## Déploiement

### 1. Provisioning (Terraform)

```bash
cd infra
terraform init
terraform apply -auto-approve
# Noter l'IP affichée : instance_ip = "X.X.X.X"
```

### 2. Inventaire (Ansible)

Mettre à jour l'IP dans `config/inventory.ini` :

```ini
[registry_hosts]
<IP_PUBLIQUE_AWS>
```

### 3. Déploiement (Ansible)

```bash
cd config
ansible-playbook -i inventory.ini deploy.yml
```

### 4. Vérification Client

Ajouter dans Docker Desktop → Settings → Docker Engine :

```json
{
  "insecure-registries": ["<IP>:5000"]
}
```

Tester la connexion :

```bash
docker login <IP>:5000
# Username: admin
# Password: admin123
```

Interface web disponible sur : `http://<IP>`
