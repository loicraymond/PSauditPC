#--------------------------------------------
#
# Nom : PSauditPC.ps1
# Date : 07/08/2024
# Auteur : Loïc RAYMOND 
# 
#--------------------------------------------

$Emplacement = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
cd $Emplacement

# Création du corps du message
$MsgCorps = ("<html><head><meta charset='utf-8'><style>body{font-family:Arial, Helvetica, sans-serif; font-size:12px; background:#efefef; max-width:980px; margin:auto;} table{border:1px; border-collapse:collapse; width:100%;} h1{color:#008fd3; text-align:center; font-size:54px;} h2{color:rgb(18, 41, 77); text-align:center;} table tbody tr td{border:1px solid rgb(18, 41, 77); padding:5px; background:#fff;} table thead tr{background:rgb(18, 41, 77);} table thead tr th{border:1px solid rgb(18, 41, 77); color:#fff; padding:5px;}</style></head>")
$MsgCorps += ("<body><h1>PSauditPC</h1>")

$dateActuelle = Get-Date -Format "dd/MM/yyyy HH:mm"

$MsgCorps += ("<p><b>Analyse réalisée le :</b> "+$dateActuelle+"</p>")

# Ordinateur audité
$MsgCorps += "<h2>Ordinateur audité</h2>"
$MsgCorps += "<table><thead><tr><th>Propriété</th><th>Valeur</th></tr></thead><tbody>"
$MsgCorps += "<tr><td><b>Nom d'hôte</b></td><td>"+$env:ComputerName+"</td></tr>"
$MsgCorps += "<tr><td><b>Domaine</b></td><td>"+$env:UserDomain+"</td></tr>"
$MsgCorps += "<tr><td><b>Domaine DNS</b></td><td>"+$env:UserDNSDomain+"</td></tr>"
$MsgCorps += "<tr><td><b>Système d'exploitation</b></td><td>"+(Get-WmiObject Win32_OperatingSystem).Caption+"</td></tr>"

$MsgCorps += "</tbody></table>"

#
# Protocoles activés
# 
$MsgCorps += "<h2>Protocoles activés</h2>"
$MsgCorps += "<table><thead><tr><th>Protocole</th><th>Etat</th></tr></thead><tbody>"

# SMBv1
# à vérifier
if((Get-SmbServerConfiguration).EnableSMB1Protocol) {
    $MsgCorps += "<tr><td>SMBv1</td><td>SMBv1</td><td><span style='color:red'>activé</span></td></tr>"
}
else
{
    $MsgCorps += "<tr><td>SMBv1</td><td><span style='color:green'>désactivé</span></td></tr>"
}


# RDP
#Pb sur PC testé : la clé est à 1 (= désactivé d'après la doc MS) alors que le RDP est activé
if((Get-ItemPropertyValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections") -eq 0) {
    $MsgCorps += "<tr><td>RDP</td><td><span style='color:red'>activé</span></td></tr>"
}
else
{
    $MsgCorps += "<tr><td>RDP</td><td><span style='color:green'>désactivé</span></td></tr>"
}

$MsgCorps += "</tbody></table>"


######################
$MsgCorps += "<h2>Options</h2>"
$MsgCorps += "<table><thead><tr><th>Option</th><th>Etat</th></tr></thead><tbody>"

# UAC
if((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System').ConsentPromptBehaviorAdmin -ge 2) {
    $MsgCorps += "<tr><td>Contrôle de compte utilisateur (UAC)</td><td><span style='color:green'>activé</span></td></tr>"
}
else
{
    $MsgCorps += "<tr><td>Contrôle de compte utilisateur (UAC)</td><td><span style='color:red'>désactivé</span></td></tr>"
}

# Pare-feu
$PareFeu_public = (Get-NetFirewallProfile -Profil public).Enabled
$PareFeu_domaine = (Get-NetFirewallProfile -Profil domain).Enabled
$PareFeu_prive = (Get-NetFirewallProfile -Profil Private).Enabled

if($PareFeu_prive -and $PareFeu_domaine -and $PareFeu_public -eq "True")
{
    $MsgCorps += "<tr><td>Pare-feu</td><td><span style=`"color:green`">activé</span></td></tr>"
}
elseif($PareFeu_prive -or $PareFeu_domaine -or $PareFeu_public -eq "False")
{
    $MsgCorps += "<tr><td>Pare-feu</td><td><span style=`"color:orange`">configuration à vérifier</span></td></tr>"
}
else
{
    $MsgCorps += "<tr><td>Pare-feu</td><td><span style=`"color:red`">désactivé</span></td></tr>"
}

# Windows Defender
if((Get-MpComputerStatus).AntivirusEnabled)
{
    $MsgCorps += "<tr><td>Windows Defender</td><td><span style=`"color:green`">activé</span></td></tr>"
}
else
{
    $MsgCorps += "<tr><td>Windows Defender</td><td><span style=`"color:red`">désactivé</span></td></tr>"
}


$MsgCorps += "</tbody></table>"


# FIN

$MsgCorps += "<div style=`"margin-top:50px; color:#888; font-size:10px;`">Développé par <a href=`"https://loic-raymond.fr`" target=`"_blank`"><b>Loïc RAYMOND</b></a> - Code Source disponible : <a href=`"https://github.com/loicraymond/PSauditPC\`" target=`"_blank`">https://github.com/loicraymond/PSauditPC</a></div></body></html>"

# Export du fichier au format HTML
$MsgCorps | out-file -filepath "audit.html"
