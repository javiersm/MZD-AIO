# Script ULTRA-SIMPLE sin limpiar node_modules
# Si ya existe, solo actualiza y compila
# Autor: Antigravity

function Print-Msg ($msg, $color = "Cyan") {
    Write-Host "`n>>> $msg" -ForegroundColor $color
}

Print-Msg "=== MZD-AIO Compilador SIMPLE ===" "Yellow"

# Node 14
$NodePath = "$PSScriptRoot\node14\node-v14.17.0-win-x64"
$env:Path = "$NodePath;$env:Path"
Print-Msg "Node: $(node -v)" "Green"

# NO LIMPIAR - Solo verificar e instalar lo que falta
if (!(Test-Path "node_modules")) {
    Print-Msg "Instalando dependencias raiz (primera vez)..." "Cyan"
    cmd /c "npm install --no-audit --legacy-peer-deps --ignore-scripts"
}
else {
    Print-Msg "node_modules ya existe, omitiendo instalacion raiz" "Green"
}

if (!(Test-Path "app\node_modules")) {
    Print-Msg "Instalando dependencias app (primera vez)..." "Cyan"
    Push-Location "app"
    cmd /c "npm install --no-audit --legacy-peer-deps --ignore-scripts --production"
    Pop-Location
}
else {
    Print-Msg "app\node_modules ya existe, omitiendo instalacion app" "Green"
}

# Compilar directamente
Print-Msg "COMPILANDO DIRECTAMENTE!" "Green"
cmd /c "npm run build:win64"

if ($LASTEXITCODE -eq 0) {
    Print-Msg "EXITO! Revisa carpeta 'releases'" "Green"
}
else {
    Print-Msg "Fallo. Intentando con electron-rebuild..." "Yellow"
    
    # Instalar electron-rebuild
    cmd /c "npm install -g @electron/rebuild 2>nul"
    
    # Rebuild app
    Push-Location "app"
    Print-Msg "Rebuild app..." "Cyan"
    cmd /c "npx electron-rebuild -v 6.1.9 -f -w drivelist"
    Pop-Location
    
    # Rebuild raiz
    Print-Msg "Rebuild raiz..." "Cyan"
    cmd /c "npx electron-rebuild -v 6.1.9 -f"
    
    # Intentar compilar de nuevo
    Print-Msg "Reintentando compilacion..." "Cyan"
    cmd /c "npm run build:win64"
    
    if ($LASTEXITCODE -eq 0) {
        Print-Msg "EXITO! Revisa carpeta 'releases'" "Green"
    }
    else {
        Print-Msg "Error final" "Red"
    }
}
