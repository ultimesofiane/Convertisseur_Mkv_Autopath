param(
    [string]$FilePath
)

# -----------------------------
# Affiche le chemin reçu
Write-Output "Chemin reçu par le script : $FilePath"

# -----------------------------
# Vérifie que le fichier existe (même avec crochets, parenthèses, espaces)
if (-not (Test-Path -LiteralPath $FilePath)) {
    Write-Output "Fichier introuvable : $FilePath"
    exit 1
}

# Ignore les dossiers
if ((Get-Item -LiteralPath $FilePath).PSIsContainer) {
    Write-Output "Le téléchargement est un dossier, ignoré."
    exit 0
}

# -----------------------------
# Variables
$animeRoot = "S:\ANIME"
$ffmpegPath = "C:\Users\%USERNAME%\Documents\Convertisseur\ffmpeg_full_build\bin\ffmpeg.exe"
$fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
$fileExt = [System.IO.Path]::GetExtension($FilePath)

# On ne traite que les MKV
if ($fileExt -ne ".mkv") {
    Write-Output "Pas un fichier MKV, ignoré."
    exit 0
}

# -----------------------------
# Fonction pour nettoyer les noms (supprime crochets, parenthèses, points, tirets)
function Normalize-Name($name) {
    return ($name -replace '[^a-zA-Z0-9]', '').ToLower()
}

$normalizedFileName = Normalize-Name $fileName

# -----------------------------
# Cherche le dossier correspondant dans S:\ANIME
$folders = Get-ChildItem -Path $animeRoot -Directory
$match = $folders | Where-Object {
    $normalizedFolder = Normalize-Name $_.Name
    $normalizedFileName -like "*$normalizedFolder*" -or $normalizedFolder -like "*$normalizedFileName*"
} | Select-Object -First 1

if (-not $match) {
    Write-Output "Aucun dossier correspondant trouvé dans $animeRoot"
    $outputDir = Join-Path $animeRoot "_UNSORTED"
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
} else {
    $outputDir = $match.FullName
    Write-Output "Correspondance trouvée : $outputDir"
}

# -----------------------------
# Prépare le chemin de sortie
$outputFile = Join-Path $outputDir "$fileName.mp4"

# Escape du chemin pour ffmpeg si nécessaire
$escapedPath = $FilePath -replace '(["`])', '``$1'

# -----------------------------
# Conversion avec ffmpeg
Write-Output "Conversion en cours..."
& "$ffmpegPath" -i "$escapedPath" -c:v copy -c:a copy "$outputFile"

if (Test-Path -LiteralPath $outputFile) {
    Write-Output "Conversion terminée : $outputFile"
    # Supprimer le fichier original si tu veux
    # Remove-Item -LiteralPath $FilePath
} else {
    Write-Output "Erreur lors de la conversion"
}

