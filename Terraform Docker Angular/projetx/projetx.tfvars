# Attention aux chemins, il faut mettre ceux qui seront appliqués à l'intérieur du conteneur Terraform et non le filesystem du serveur

# Les clés ssh ne doivent jamais être mises dans un repo Git. Utilisez un gestionnaire de secrets pour les sauvegarder.
vmsshpublickey      = "/sshkeys/ProjetXPublicKey"
vmsshprivatekey     = "/sshkeys/ProjetXPrivateKey"
githubsshprivatekey = "/sshkeys/GithubPrivateKey"
vscodesshpublickey  = "/sshkeys/VsCodePublicKey"
sshconf             = "/sshkeys/sshconf"

# caractéristiques de la VM
name                = "projetx"
vmsize              = "Standard_B2S"
vnetaddrspace       = ["10.2.0.0/16"]
subnetprefix        = ["10.2.1.0/24"]

# script d'initialisation
initscript          = "/terraform/projetx/projetx-init.sh"

