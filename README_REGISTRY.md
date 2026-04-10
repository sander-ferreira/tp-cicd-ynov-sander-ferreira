# Déploiement d'un Registre Docker Privé sur AWS

Infrastructure permanente, à provisionner **une fois** avant de pouvoir lancer le pipeline applicatif.

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.2
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
- [AWS CLI](https://aws.amazon.com/cli/) configuré (`aws configure`)

## Structure

```markdown
infra-registry/   → Code Terraform (EC2, Security Group, Key Pair)
registry/         → Playbook Ansible + templates Docker Compose + nginx
```

## 1. Provisioning (Terraform)

```bash
cd infra-registry
terraform init
terraform apply -auto-approve
# Note l'IP affichée en output : instance_ip = "X.X.X.X"
# La clé SSH est écrite localement dans registry-key-terraform.pem
```

## 2. Inventaire (Ansible)

Mettre à jour l'IP dans [registry/inventory.ini](registry/inventory.ini) :

```ini
[registry_hosts]
<IP_PUBLIQUE_AWS>

[registry_hosts:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=../infra-registry/registry-key-terraform.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

## 3. Déploiement (Ansible)

Le mot de passe du registry est passé en variable au runtime (jamais en clair dans le repo) :

```bash
cd registry
ansible-playbook -i inventory.ini deploy.yml \
  --extra-vars "registry_admin_password=<MOT_DE_PASSE>"
```

Le playbook installe Docker, génère le certificat SSL self-signed (avec SAN sur l'IP), crée le htpasswd et démarre la stack `nginx + registry + ui`.

## 4. Récupération du certificat pour les GitHub Secrets

Le pipeline applicatif a besoin de faire confiance au certificat self-signed. Récupère-le pour le coller dans le secret `REGISTRY_CERT` :

```bash
ssh -i infra-registry/registry-key-terraform.pem \
    ubuntu@<IP_REGISTRY> \
    "sudo cat /home/ubuntu/registry/nginx/certs/registry.crt"
```

## 5. Vérification

Test de connexion Docker :

```bash
docker login <IP_REGISTRY>:443
# Username: <USERNAME>
# Password: <MOT_DE_PASSE>
```

Interface web : `https://<IP_REGISTRY>` (accepter le warning cert self-signed)

## Services exposés

| Port | Usage                                                                                       |
|------|---------------------------------------------------------------------------------------------|
| 22   | SSH (admin Ansible uniquement)                                                              |
| 80   | Redirect 301 vers HTTPS                                                                     |
| 443  | Nginx HTTPS : `/v2/*` → API Docker Registry, `/*` → Interface web (joxit/docker-registry-ui) |
