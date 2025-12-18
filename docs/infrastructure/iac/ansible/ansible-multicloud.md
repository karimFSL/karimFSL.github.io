---
sidebar_position: 1
---

# ⚙️ Ansible - Configuration Multi-Cloud

Ansible automatise la configuration des serveurs après leur provisionnement par Terraform, dans une approche **Infrastructure as Code** complète.

## 🎯 Ansible dans l'écosystème DevSecOps

```mermaid
graph TB
    subgraph "Phase 1: Provisionnement"
        TF[📦 Terraform]
        AWS[☁️ AWS]
        AZURE[☁️ Azure]
        GCP[☁️ GCP]
        SECNUM[🔒 SecNumCloud]
    end
    
    subgraph "Phase 2: Configuration"
        ANSIBLE[⚙️ Ansible]
        PLAYBOOKS[📝 Playbooks]
        ROLES[🎭 Roles]
    end
    
    subgraph "Phase 3: Déploiement Apps"
        CICD[🔄 GitLab CI]
        JAVA[☕ Java]
        DRUPAL[🔷 Drupal]
        ANGULAR[🅰️ Angular]
    end
    
    subgraph "Phase 4: Monitoring"
        PROM[📊 Prometheus]
        GRAF[📈 Grafana]
    end
    
    TF --> AWS
    TF --> AZURE
    TF --> GCP
    TF --> SECNUM
    
    AWS --> ANSIBLE
    AZURE --> ANSIBLE
    GCP --> ANSIBLE
    SECNUM --> ANSIBLE
    
    ANSIBLE --> PLAYBOOKS
    ANSIBLE --> ROLES
    
    PLAYBOOKS --> CICD
    ROLES --> CICD
    
    CICD --> JAVA
    CICD --> DRUPAL
    CICD --> ANGULAR
    
    JAVA --> PROM
    DRUPAL --> PROM
    ANGULAR --> PROM
    PROM --> GRAF
```

## 💡 Concept : Séparation des responsabilités

### 🔧 Terraform → Provisionner
**Rôle** : Créer l'infrastructure cloud
- VPC, subnets, security groups
- Instances EC2, VMs Azure, Compute Engine GCP
- Load balancers, databases managées
- Stockage S3, Azure Blob, GCS

**Sortie Terraform** → Inventory Ansible
```hcl
# Terraform génère automatiquement l'inventory Ansible
output "ansible_inventory" {
  value = {
    webservers = aws_instance.web[*].public_ip
    databases  = aws_instance.db[*].private_ip
    cache      = aws_instance.redis[*].private_ip
  }
}
```

### ⚙️ Ansible → Configurer
**Rôle** : Configurer les serveurs provisionnés
- Installation packages (Nginx, PostgreSQL, Redis)
- Configuration système (firewall, users, SSH)
- Hardening sécurité (fail2ban, SELinux)
- Monitoring agents (Prometheus exporters)

**Exécution** : Juste après Terraform
```bash
# 1. Terraform crée les serveurs
terraform apply

# 2. Ansible les configure
ansible-playbook -i inventory/production playbooks/site.yml

# 3. CI/CD déploie les applications
```

### 🚀 CI/CD → Déployer
**Rôle** : Déployer les applications métier
- Build des artefacts (JAR, images Docker)
- Déploiement sur Kubernetes
- Rolling updates
- Health checks

## 📁 Structure projet intégrée

```
infrastructure/
├── terraform/                    # Phase 1: Provisionnement
│   ├── aws/
│   │   ├── main.tf
│   │   └── outputs.tf          # → Génère inventory Ansible
│   ├── azure/
│   └── gcp/
│
├── ansible/                      # Phase 2: Configuration
│   ├── inventory/
│   │   ├── production.yml      # ← Généré par Terraform
│   │   └── group_vars/
│   ├── playbooks/
│   │   ├── site.yml            # Configure tout
│   │   └── bootstrap.yml       # Premier démarrage
│   └── roles/
│       ├── common/             # Packages de base
│       ├── nginx/              # Web servers
│       ├── postgresql/         # Databases
│       └── monitoring/         # Prometheus exporters
│
└── applications/                 # Phase 3: Applications
    ├── java-app/
    │   └── .gitlab-ci.yml      # Pipeline CI/CD
    ├── drupal-site/
    │   └── .gitlab-ci.yml
    └── angular-app/
        └── .gitlab-ci.yml
```

## 🌍 Multi-Cloud avec Ansible

### Approche : Inventories par cloud provider

```yaml title="inventory/aws-production.yml"
all:
  children:
    aws_webservers:
      hosts:
        web01-aws: {ansible_host: 10.0.1.10}
        web02-aws: {ansible_host: 10.0.1.11}
      vars:
        cloud_provider: aws
        region: eu-west-1

    aws_databases:
      hosts:
        db01-aws: {ansible_host: 10.0.2.10}
```

```yaml title="inventory/azure-production.yml"
all:
  children:
    azure_webservers:
      hosts:
        web01-azure: {ansible_host: 10.1.1.10}
        web02-azure: {ansible_host: 10.1.1.11}
      vars:
        cloud_provider: azure
        region: westeurope
```

```yaml title="inventory/secnumcloud-production.yml"
all:
  children:
    secnum_webservers:
      hosts:
        web01-secnum: {ansible_host: 10.2.1.10}
      vars:
        cloud_provider: secnumcloud
        compliance: qualifié
```

### Playbooks cloud-agnostic

```yaml title="playbooks/site.yml"
---
# Configure TOUS les serveurs (AWS + Azure + GCP + SecNumCloud)
- name: Configure all servers
  hosts: all
  roles:
    - common              # Installation de base (identique partout)
    - security           # Hardening (identique partout)
    - monitoring         # Exporters Prometheus

- name: Configure web servers
  hosts: "*_webservers"   # Toutes les VMs web de tous les clouds
  roles:
    - nginx

- name: Configure databases
  hosts: "*_databases"
  roles:
    - postgresql
```

**Avantage** : Le même playbook fonctionne sur tous les clouds ! 🎯

## 🔄 Intégration avec CI/CD GitLab

### Pipeline GitLab CI complet

```yaml title=".gitlab-ci.yml"
stages:
  - provision      # Terraform
  - configure      # Ansible
  - deploy         # Application

# Stage 1: Terraform provisionne
provision:infrastructure:
  stage: provision
  image: hashicorp/terraform:latest
  script:
    - cd terraform/aws
    - terraform init
    - terraform apply -auto-approve
    - terraform output -json > ../../ansible-inventory.json
  artifacts:
    paths:
      - ansible-inventory.json

# Stage 2: Ansible configure
configure:servers:
  stage: configure
  image: cytopia/ansible:latest
  dependencies:
    - provision:infrastructure
  script:
    - cd ansible
    - ansible-playbook -i ../ansible-inventory.json playbooks/site.yml
  only:
    - main

# Stage 3: Déploiement application
deploy:java:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/my-app app=registry.com/my-app:$CI_COMMIT_SHA
  only:
    - main
```

### Workflow complet

```mermaid
sequenceDiagram
    participant Dev as 👨‍💻 Développeur
    participant Git as 📦 GitLab
    participant TF as 🏗️ Terraform
    participant Cloud as ☁️ AWS/Azure/GCP
    participant Ansible as ⚙️ Ansible
    participant App as 🚀 Application
    
    Dev->>Git: git push
    Git->>TF: Stage 1: Provision
    TF->>Cloud: Create VMs
    Cloud-->>TF: IPs des serveurs
    TF->>Git: Génère inventory.json
    
    Git->>Ansible: Stage 2: Configure
    Ansible->>Cloud: SSH vers VMs
    Ansible->>Cloud: Install Nginx, PostgreSQL...
    Cloud-->>Ansible: Serveurs configurés
    
    Git->>App: Stage 3: Deploy
    App->>Cloud: Deploy app sur K8s
    Cloud-->>Dev: ✅ Done!
```

## 🎭 Cas d'usage : Déploiement multi-région

### Scénario
Déployer la même stack Java sur 3 clouds simultanément :
- **AWS eu-west-1** : Production Europe
- **Azure westeurope** : Backup Europe  
- **GCP us-central1** : Production US

### Solution avec Ansible

```yaml title="playbooks/deploy-multicloud.yml"
---
- name: Deploy on ALL clouds
  hosts: all
  serial: "30%"           # 30% des serveurs à la fois
  max_fail_percentage: 10  # Stop si >10% d'échecs
  
  pre_tasks:
    - name: Health check avant déploiement
      uri:
        url: http://localhost:8080/health
      register: health
      
  roles:
    - java-deployment
    
  post_tasks:
    - name: Smoke test après déploiement
      uri:
        url: http://localhost:8080/actuator/health
        status_code: 200
```

**Commande** :
```bash
# Déploie sur les 3 clouds en parallèle
ansible-playbook playbooks/deploy-multicloud.yml \
  -i inventory/aws-production.yml \
  -i inventory/azure-production.yml \
  -i inventory/gcp-production.yml
```

## 🔒 Sécurité et Secrets

### Ansible Vault pour les secrets

```yaml title="group_vars/all/vault.yml"
# Fichier chiffré avec ansible-vault
---
vault_db_password: "SuperSecret123"
vault_api_key: "sk-1234567890abcdef"
vault_ssh_private_key: |
  -----BEGIN RSA PRIVATE KEY-----
  ...
  -----END RSA PRIVATE KEY-----
```

```bash
# Chiffrer le fichier
ansible-vault encrypt group_vars/all/vault.yml

# Utiliser dans les playbooks
ansible-playbook site.yml --ask-vault-pass

# Ou avec un fichier de mot de passe
echo "my-vault-password" > .vault_pass
ansible-playbook site.yml --vault-password-file .vault_pass
```

### Intégration HashiCorp Vault

```yaml
- name: Get secrets from Vault
  set_fact:
    db_password: "{{ lookup('hashi_vault', 'secret=secret/db/password') }}"
    api_key: "{{ lookup('hashi_vault', 'secret=secret/api/key') }}"
```

## 📊 Monitoring de l'exécution Ansible

### Callbacks pour logs structurés

```ini title="ansible.cfg"
[defaults]
# Logs JSON pour parsing
stdout_callback = json
# Profiling des tâches lentes
callback_whitelist = profile_tasks, timer
# Log vers fichier
log_path = /var/log/ansible/ansible.log
```

### Intégration avec GitLab CI

```yaml
configure:servers:
  script:
    - ansible-playbook site.yml --diff | tee ansible-output.log
    - cat ansible-output.log
  artifacts:
    when: always
    paths:
      - ansible-output.log
    reports:
      junit: ansible-junit.xml
```

## 🎯 Bonnes pratiques

### ✅ À faire

| Pratique | Pourquoi |
|----------|----------|
| **Idempotence** | Rejouer le playbook n'a pas d'effet de bord |
| **Variables par environnement** | `group_vars/production/`, `group_vars/staging/` |
| **Roles réutilisables** | Un rôle = une responsabilité |
| **Tags** | `--tags "nginx,security"` pour exécutions partielles |
| **Dry-run** | `--check --diff` avant la vraie exécution |
| **Version des rôles** | `requirements.yml` pour les dépendances |

### ❌ À éviter

| Anti-pattern | Problème |
|--------------|----------|
| Commandes `shell` partout | Pas idempotent, difficile à maintenir |
| Secrets en clair | Toujours utiliser Ansible Vault |
| Playbooks monolithiques | Difficile à tester et réutiliser |
| Pas de rollback | Prévoir un playbook de rollback |

## 🚀 Exemple complet : Bootstrap infrastructure

```yaml title="playbooks/bootstrap.yml"
---
# Ce playbook est lancé APRÈS Terraform et AVANT les apps
- name: Bootstrap all new servers
  hosts: all
  become: yes
  
  tasks:
    # 1. Packages de base
    - name: Update system
      apt:
        update_cache: yes
        upgrade: dist
        
    - name: Install base packages
      apt:
        name:
          - vim
          - curl
          - git
          - htop
          - fail2ban
        state: present
        
    # 2. Utilisateurs et SSH
    - name: Create deployment user
      user:
        name: deploy
        shell: /bin/bash
        groups: sudo
        
    - name: Disable password authentication
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PasswordAuthentication'
        line: 'PasswordAuthentication no'
      notify: restart sshd
        
    # 3. Monitoring
    - name: Install node_exporter
      include_role:
        name: prometheus.prometheus.node_exporter
        
  handlers:
    - name: restart sshd
      service:
        name: sshd
        state: restarted
```

## 📈 Résumé de la chaîne complète

| Étape | Outil | Responsabilité | Résultat |
|-------|-------|----------------|----------|
| 1️⃣ | **Terraform** | Provisionner VMs | Serveurs vides avec OS |
| 2️⃣ | **Ansible** | Configurer serveurs | Serveurs prêts pour apps |
| 3️⃣ | **GitLab CI** | Déployer applications | Apps running en production |
| 4️⃣ | **Prometheus** | Monitorer | Dashboards et alertes |

---

**Ansible est le pont entre l'infrastructure (Terraform) et les applications (CI/CD) ! 🌉**