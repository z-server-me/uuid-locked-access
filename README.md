# README - Verrouiller l'accès à un seul dock USB (UUID spécifique) dans PBS

## ✨ Objectif
Empêcher que Proxmox Backup Server (PBS) accède ou monte un autre disque que le RAID USB autorisé, identifié par son UUID :

```
UUID=e55055f6-c8a4-45a0-a0a3-d3c12ab12905
```

## ✅ Étapes réalisées

### 1. Configuration de `/etc/fstab`
Pour s'assurer que **seul ce disque est monté automatiquement** (et ne bloque pas le boot si absent) :

```fstab
UUID=e55055f6-c8a4-45a0-a0a3-d3c12ab12905 /mnt/pveusbkp ext4 defaults,nofail 0 2
```

### 2. Création du point de montage

```bash
mkdir -p /mnt/pveusbkp
```

### 3. Test du montage manuel

```bash
mount -a
```

Vérifier :
```bash
df -h | grep pveusbkp
```

### 4. Blocage des montages automatiques de disques USB non autorisés (udev)

Fichier udev pour **ignorer tous les disques sauf l'UUID autorisé** :

```bash
nano /etc/udev/rules.d/99-allow-only-authorized-usb.rules
```

Contenu :
```udev
# Autoriser uniquement le disque avec cet UUID, bloquer les autres
action=="add|change", KERNEL=="sd[b-z][0-9]", ENV{ID_FS_UUID}!="e55055f6-c8a4-45a0-a0a3-d3c12ab12905", ENV{UDISKS_IGNORE}="1"
```

Recharger les règles :
```bash
udevadm control --reload-rules
udevadm trigger
```

### 5. Surveillance optionnelle (script cron + Telegram)

Script pour vérifier que **seul l'UUID autorisé** est présent :

```bash
nano /home/scripts/check-only-authorized-disk.sh
```

Contenu :
```bash
#!/bin/bash
AUTHORIZED_UUID="e55055f6-c8a4-45a0-a0a3-d3c12ab12905"
FOUND=$(lsblk -o UUID | grep -v "$AUTHORIZED_UUID" | grep -v "^$" | wc -l)

if [ "$FOUND" -ne 0 ]; then
  echo "Disque non autorisé détecté sur PBS !" | \
  curl -s -X POST "https://api.telegram.org/bot<token>/sendMessage" \
  -d chat_id=<chat_id> -d text="$(hostname): Un disque non autorisé est branché !"
fi
```

Rendre le script exécutable :
```bash
chmod +x /home/scripts/check-only-authorized-disk.sh
```

Ajout dans `crontab` (toutes les 15 minutes) :
```bash
crontab -e
```
Contenu :
```cron
*/15 * * * * /home/scripts/check-only-authorized-disk.sh
```

## 📄 Conclusion
- Le disque USB RAID de 4 To est monté de manière fiable
- Aucun autre disque ne peut être monté automatiquement
- Le système démarre toujours proprement (grâce à `nofail`)
- Une alerte peut être envoyée si un disque non autorisé est connecté

Tu es blindé 🚀

