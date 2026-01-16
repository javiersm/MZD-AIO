# Instrucciones de Compilación (MZD-AIO)

Este proyecto es antiguo y requiere un entorno específico para compilarse.
He automatizado parte del proceso descargando **Node 14 (Portable)** en la carpeta `node14` dentro de este proyecto.

## Requisitos Previos (OBLIGATORIO)

Para generar el archivo `.exe` en Windows, es **IMPRESCINDIBLE** que tengas instaladas las herramientas de compilación de C++:

1.  Descarga **[Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)**.
    *   **¡OJO!** No es "Visual Studio Code" (el editor azul). Es un instalador diferente (suele ser morado).
    *   El programa se llamará "Visual Studio Installer".
2.  Ejecuta el instalador.
3.  En la pestaña "Cargas de trabajo" (Workloads), marca **SOLO** la casilla:
    *   **"Desarrollo para el escritorio con C++"** (Desktop development with C++).
    *   *No necesitas instalar nada más.*
4.  Instálalo y REINICIA tu terminal (o el PC si es necesario).

## Cómo Compilar (Paso a Paso)

Una vez instalados los requisitos, abre una termina (Powershell) en la carpeta de este proyecto y ejecuta:

### 1. Configurar Node 14 (Portable)
Esto usa la versión correcta de Node sin afectar a tu instalación principal de Node 22.
```powershell
$env:Path = "$PWD\node14\node-v14.17.0-win-x64;" + $env:Path
```

### 2. Instalar Librerías
Gracias a las Build Tools instaladas, esto ahora compilará `drivelist` correctamente.
```powershell
npm install
```
*(Si da error EPERM, cierra todos los programas y carpetas y reintenta)*

### 3. Crear Instalador (.exe)
Al terminar, tendrás el instalador en la carpeta `releases`.
```powershell
npm run build:win
```

