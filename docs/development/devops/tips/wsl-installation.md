---
sidebar_position: 1
---
# Installation de WSL 2 et Docker

## Installation de WSL
Entrez cette commande dans PowerShell puis redémarrez votre machine :
```powershell
wsl --install
```

Vérifiez la version de distribution, elle doit être Ubuntu :
```powershell
wsl -l
```

Si Ubuntu n'est pas installé :
```powershell
wsl --install -d Ubuntu
```

Si Ubuntu n'est pas défini par défaut :
```powershell
wsl -s Ubuntu
```

---

## Installation de Docker dans WSL2

Lancez WSL depuis le menu Windows.

### Installation
```bash
sudo apt-get update

sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io
```

### Lancer Docker
```bash
sudo service docker start
```

> **Note :** Après chaque redémarrage, vous devez ouvrir WSL et lancer Docker (ou voir la section AutoStart ci-dessous).

---

## Installation de docker-compose
```bash
sudo curl -SL https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
```

> **Important :** Le dépôt par défaut n'est pas à jour. Si vous installez docker-compose avec `sudo apt install docker-compose`, la version sera une ancienne version 1.25.0.

---

## Gestion de Docker

### Exposition de Docker sur localhost

Si vous souhaitez gérer Docker avec le plugin Docker d'IntelliJ, vous devez exposer Docker sur localhost.

Ajoutez dans le fichier `/etc/default/docker` :
```bash
export DOCKER_OPTS="--host unix:// --host tcp://127.0.0.1:2375"
```

### Alternative : Portainer

Vous pouvez également installer un conteneur Portainer pour gérer votre environnement Docker.

---

## Astuces

### WSL + VPN

Si vous rencontrez des problèmes réseau lors du démarrage de WSL avec un VPN, vous pouvez utiliser cette image WSL pour créer un pont entre HyperV et l'hôte.

Image à utiliser : `wsl-vpnkit-v0.3.8.tar.gz` (utilisez uniquement cette version 0.3.8)

#### Installation

Ouvrez une invite PowerShell et exécutez les commandes suivantes :
```powershell
wsl --import wsl-vpnkit $env:USERPROFILE\wsl-vpnkit wsl-vpnkit-v0.3.8.tar.gz --version 2
```

Exécutez cette commande chaque fois que vous perdez la connectivité réseau lors de la connexion au VPN :
```powershell
wsl.exe -d wsl-vpnkit service wsl-vpnkit start
```

---

### Éviter sudo

Pour ajouter l'utilisateur WSL au groupe Docker et éviter d'exécuter Docker avec sudo (facultatif) :
```bash
sudo usermod -aG docker $USER
```

---

### AutoStart

Pour démarrer automatiquement Docker au lancement de WSL :

1. Éditez sudoers :
```bash
sudo visudo
```

2. Ajoutez à la fin du fichier :
```bash
# Docker daemon specification
[user_ubuntu] ALL=(ALL) NOPASSWD: /usr/bin/dockerd
```

3. Éditez bashrc :
```bash
vi ~/.bashrc
```

4. Ajoutez à la fin du fichier :
```bash
# Start Docker daemon automatically when logging in if not running.
RUNNING=`ps aux | grep dockerd | grep -v grep`
if [ -z "$RUNNING" ]; then
    sudo dockerd > /dev/null 2>&1 &
    disown
fi
```

---

### Backup / Restore

Pour sauvegarder des volumes depuis Docker Desktop et les restaurer dans WSL :

- `${PWD}` = variable pour le répertoire courant
- `[VOLUME]` = nom du volume

#### Backup
```bash
docker run --rm -it -v ${PWD}:/destination -v [VOLUME]:/source ubuntu bash
cd /source && tar cvf /destination/[VOLUME].tar
exit
```

#### Restore
```bash
docker run --rm -it -v ${PWD}:/source -v [VOLUME]:/destination ubuntu bash
cd /destination && tar xvf /source/[VOLUME].tar
exit
```
