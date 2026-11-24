# Fusion automatique Multisport `.FIT` → Garmin Connect

Sur **Forerunner 165 Music**, l'API Connect IQ enregistre chaque discipline dans un fichier `.FIT` séparé (`[MS:261124_1625 1/5] Natation`, `2/5 T1`, `3/5 Vélo`, `4/5 T2`, `5/5 Course`).

Ce workflow GitHub Actions (`.github/workflows/merge-multisport.yml`) surveille ton compte Garmin Connect toutes les 30 minutes, fusionne automatiquement les fichiers `.FIT` d'un même multisport en **une seule activité Multisport / Triathlon native** et la renvoie sur Garmin Connect.

## Mise en place (2 minutes)

1. Connecte GitHub CLI si ce n'est pas déjà fait :
   ```powershell
   gh auth login
   ```
2. Crée un dépôt privé et pousse le projet :
   ```powershell
   git init
   git add .
   git commit -m "Initial Multisport 965 Watch App + FIT Merger"
   gh repo create garmin-multisport-965 --private --source=. --push
   ```
3. Ajoute tes identifiants Garmin Connect en **Secrets GitHub** (chiffrés, jamais en clair dans le code) :
   ```powershell
   gh secret set GARMIN_EMAIL
   gh secret set GARMIN_PASSWORD
   ```
4. Active GitHub Actions sur le dépôt : la fusion tournera automatiquement toutes les 30 min (ou à la demande via l'onglet **Actions → Merge Garmin Multisport FIT → Run workflow**).
