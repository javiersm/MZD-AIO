# ANALISIS COMPLETO DEL PROYECTO MZD-AIO-TI

## Documento de Referencia para Desarrollo y Modificacion

**Proyecto:** MZD-AIO-TI (MZD All In One Tweaks Installer)
**Version analizada:** 2.8.6
**Autor original:** Trevor G Martin (Trevelopment)
**Repositorio:** https://github.com/Trevelopment/MZD-AIO
**Licencia:** GPL-3.0

---

## 1. QUE ES MZD-AIO Y PARA QUE SIRVE

MZD-AIO es una **aplicacion de escritorio** (Windows, macOS, Linux) que permite:

1. **Seleccionar modificaciones (tweaks)** para el sistema de infoentretenimiento Mazda Connect
2. **Compilar scripts de instalacion** (.sh) que se ejecutan en el CMU del vehiculo
3. **Generar una carpeta USB** lista para copiar e instalar en el Mazda

**IMPORTANTE:** El proyecto **NO emula el sistema Mazda**. Es un **generador de scripts** que crea archivos de instalacion para modificar el firmware real del vehiculo.

---

## 2. ARQUITECTURA GENERAL

```
+------------------------------------------------------------------+
|                    APLICACION DE ESCRITORIO                       |
|                         (Electron + AngularJS)                    |
+------------------------------------------------------------------+
|  Frontend (Renderer Process)  |  Backend (Main Process)          |
|  - AngularJS UI               |  - Node.js/Electron              |
|  - HTML/CSS/Bootstrap         |  - Sistema de archivos           |
|  - Seleccion de tweaks        |  - Comunicacion IPC              |
|  - Configuracion visual       |  - Deteccion USB                 |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                    CARPETA _copy_to_usb                          |
|  - tweaks.sh (script maestro)                                    |
|  - config/ (archivos de configuracion)                           |
|  - Imagenes, temas, etc.                                         |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                    CMU DEL MAZDA (Linux embedded)                |
|  - Ejecuta tweaks.sh desde USB                                   |
|  - Modifica sistema JCI                                          |
|  - Aplica cambios permanentes                                    |
+------------------------------------------------------------------+
```

---

## 3. ESTRUCTURA DE CARPETAS DEL PROYECTO

```
MZD-AIO/
|
+-- app/                          # CARPETA PRINCIPAL DE LA APP
|   +-- main.js                   # Proceso principal Electron (PUNTO DE ENTRADA)
|   +-- preload.js                # Script de precarga para seguridad
|   +-- index.html                # Vista principal HTML
|   +-- package.json              # Dependencias de la app
|   |
|   +-- controllers/
|   |   +-- home.js               # Controlador AngularJS principal (40KB)
|   |
|   +-- assets/
|   |   +-- js/
|   |   |   +-- index.js          # Helpers del renderer
|   |   |   +-- events.js         # Eventos IPC
|   |   |   +-- build-tweaks.js   # MOTOR DE COMPILACION (63KB) ***
|   |   |   +-- aapatcher.js      # Parchador Android Auto
|   |   |   +-- speedoConfig.js   # Config velocimetro
|   |   |   +-- notifications.js  # Sistema notificaciones
|   |   |   +-- ... (mas scripts)
|   |   +-- vendor/               # Librerias terceros (jQuery, Angular, etc)
|   |   +-- css/                  # Estilos
|   |   +-- images/               # Imagenes UI
|   |
|   +-- views/                    # Vistas HTML
|   |   +-- main.htm              # Vista principal de tweaks (27K lineas)
|   |   +-- help.htm              # Ayuda
|   |   +-- casdk.htm             # CASDK manager
|   |   +-- translate.html        # Traductor
|   |   +-- serial.html           # Conexion serial
|   |   +-- ... (mas vistas)
|   |
|   +-- opts/                     # Opciones de cada tweak (HTML)
|   |   +-- 1options.htm          # Opciones tweak 1
|   |   +-- 2options.htm          # etc...
|   |   +-- coloroptions.htm
|   |   +-- mainmenuoptions.htm
|   |
|   +-- files/                    # ARCHIVOS DE TWEAKS ***
|   |   +-- tweaks/               # Scripts de instalacion
|   |   |   +-- 00_intro.txt      # Introduccion
|   |   |   +-- 00_start.txt      # UTILIDADES PRINCIPALES (445KB) ***
|   |   |   +-- 00_backup.txt     # Backup
|   |   |   +-- 01_touchscreen-i.txt  # Instalar touchscreen
|   |   |   +-- 01_touchscreen-u.txt  # Desinstalar touchscreen
|   |   |   +-- ... (50+ scripts)
|   |   |   +-- 00_end.txt        # Final
|   |   |   |
|   |   |   +-- config/           # Archivos a copiar al CMU
|   |   |   |   +-- jci/          # Sistema JCI Mazda
|   |   |   |   +-- androidauto/
|   |   |   |   +-- bootanimation/
|   |   |   |   +-- video_player/
|   |   |   |   +-- ... (mas configs)
|   |   |   |
|   |   |   +-- casdk/            # Custom App SDK
|   |   |   +-- casdkapps/        # Apps CASDK compiladas
|   |   |   +-- cmu-autorun/      # Scripts de recuperacion
|   |
|   +-- lang/                     # Idiomas (JSON)
|   |   +-- english.aio.json
|   |   +-- spanish.aio.json
|   |   +-- ... (mas idiomas)
|   |
|   +-- lib/                      # Librerias internas
|   |   +-- log.js                # Sistema de logging
|   |   +-- menu.js               # Menu Electron
|   |   +-- auto-update/          # Actualizacion automatica
|   |
|   +-- menus/                    # Definicion de menus
|
+-- build/                        # Scripts de compilacion
+-- background-images/            # Imagenes de fondo default
+-- castscreenApp/                # APKs de CastScreen
+-- scripts/                      # Scripts de build
+-- test/                         # Tests
+-- package.json                  # Dependencias principales
+-- README.md
```

---

## 4. ARCHIVOS CLAVE QUE DEBES CONOCER

### 4.1 app/main.js - Proceso Principal Electron
**Funcion:** Punto de entrada de la aplicacion, gestiona:
- Creacion de ventanas
- Comunicacion IPC con el renderer
- Dialogos de archivos
- Deteccion de USB
- Actualizaciones automaticas
- Configuracion persistente

### 4.2 app/controllers/home.js - Controlador AngularJS
**Funcion:** Logica de la interfaz de usuario:
- Estado del usuario (`$scope.user`)
- Seleccion de tweaks
- Inicio de compilacion
- Guardar/cargar configuraciones
- Manejo de eventos UI

### 4.3 app/assets/js/build-tweaks.js - Motor de Compilacion
**Funcion:** Genera los archivos de instalacion:
- Compila `tweaks.sh` concatenando scripts
- Copia archivos de configuracion
- Prepara carpeta `_copy_to_usb`
- Genera logs de compilacion

### 4.4 app/files/tweaks/00_start.txt - Utilidades del CMU
**Funcion:** Script base con funciones para el CMU:
- `get_cmu_sw_version()` - Detecta version firmware
- `compatibility_check()` - Verifica compatibilidad
- `backup_org()` - Crea backups de archivos
- `restore_org()` - Restaura backups
- Variables de entorno del sistema

---

## 5. COMO FUNCIONA EL SISTEMA MAZDA (CMU)

### 5.1 Que es el CMU
El **CMU (Connectivity Master Unit)** es la computadora del sistema de infoentretenimiento Mazda Connect. Ejecuta:
- **Linux embedded** como sistema operativo
- **JCI (Jaguar Connected Interface)** como framework de UI
- **Opera/WebKit** como motor de renderizado

### 5.2 Estructura del Sistema de Archivos del CMU

```
/jci/                           # Framework principal
  /gui/                         # Interfaz grafica
    /apps/                      # Aplicaciones nativas
    /common/js/Common.js        # Logica compartida (CLAVE)
  /opera/                       # Motor de renderizado
    opera_dir/userjs/           # JavaScript personalizado
  /scripts/                     # Scripts del sistema
  /version.ini                  # Informacion de firmware

/data_persist/dev/              # Datos persistentes
  /bin/                         # Binarios ejecutables

/tmp/mnt/resources/             # Recursos temporales
  /aio/                         # Recursos del AIO
```

### 5.3 Versiones de Firmware Soportadas

| Grupo | Versiones | Notas |
|-------|-----------|-------|
| 7 | 70.00.336+ | Mas reciente |
| 6 | 70.00.XXX | |
| 5 | 59.00.5XX | |
| 4 | 59.00.4XX | |
| 3 | 59.00.3XX | |
| 2 | 58.00.XXX | |
| 1 | 55.00.XXX - 56.00.XXX | Mas antiguo |

---

## 6. FLUJO DE COMPILACION DE TWEAKS

### Paso 1: Seleccion en la UI
El usuario selecciona tweaks en la interfaz. Se almacenan en `$scope.user.options[]`.

### Paso 2: Validacion
Al presionar "Start Compilation":
- Verifica que hay tweaks seleccionados
- Verifica archivos necesarios (color schemes, etc.)
- Muestra dialogo de confirmacion

### Paso 3: Compilacion (build-tweaks.js)
```javascript
function buildTweakFile(user, apps) {
  // 1. Limpiar carpeta anterior
  rimraf(tmpdir)  // _copy_to_usb

  // 2. Crear estructura
  mkdirp(tmpdir)

  // 3. Compilar tweaks.sh
  // Concatena: 00_intro.txt + 00_start.txt + [tweaks seleccionados] + 00_end.txt

  // 4. Copiar archivos de configuracion
  // Copia desde app/files/tweaks/config/ a _copy_to_usb/config/

  // 5. Agregar personalizaciones
  // Fondos, colores, velocimetro, etc.
}
```

### Paso 4: Resultado
Carpeta `_copy_to_usb/` con:
```
_copy_to_usb/
  +-- tweaks.sh           # Script maestro de instalacion
  +-- config/             # Archivos de configuracion
  +-- [imagenes]          # Fondos personalizados
  +-- [color schemes]     # Esquemas de color
```

### Paso 5: Instalacion en el Vehiculo
1. Copiar contenido de `_copy_to_usb/` a USB
2. Insertar USB en el Mazda
3. El CMU detecta y ejecuta `tweaks.sh`
4. Se aplican las modificaciones

---

## 7. EJEMPLO: COMO FUNCIONA UN TWEAK

### Tweak: Touchscreen mientras se conduce

**Archivo de instalacion:** `app/files/tweaks/01_touchscreen-i.txt`

```bash
# Modifica Common.js para desactivar restriccion de velocidad
sed -i 's/ .Global.AtSpeed/ \/\/"Global.AtSpeed/g' /jci/gui/common/js/Common.js

# Ejecuta script de configuracion del CMU
/jci/scripts/set_speed_restriction_config.sh disable

# Envia mensaje D-Bus para desactivar restriccion
dbus-send --address=unix:path=/tmp/dbus_hmi_socket \
  /com/jci/testdiag com.jci.testdiag.DVD_SpeedRestriction_Enable boolean:false
```

**Archivo de desinstalacion:** `app/files/tweaks/01_touchscreen-u.txt`
- Restaura el archivo original desde backup (.org)
- Reactiva la restriccion

---

## 8. COMUNICACION IPC (Frontend <-> Backend)

### Canales Principales

| Canal | Direccion | Proposito |
|-------|-----------|-----------|
| `open-file-bg` | Renderer -> Main | Abrir dialogo de fondo |
| `selected-bg` | Main -> Renderer | Fondo seleccionado |
| `download-aio-files` | Renderer -> Main | Descargar archivos |
| `dl-progress` | Main -> Renderer | Progreso descarga |
| `start-compile` | Renderer -> Main | Iniciar compilacion |
| `save-options` | Bidireccional | Guardar configuracion |
| `load-options` | Bidireccional | Cargar configuracion |

### Ejemplo de uso:
```javascript
// En renderer (events.js)
ipc.send('open-file-bg')  // Solicita abrir dialogo

// En main (main.js)
ipc.on('open-file-bg', () => {
  dialog.showOpenDialog(/* opciones */)
    .then(result => {
      ipc.send('selected-bg', result.filePaths[0])
    })
})

// En renderer (events.js)
ipc.on('selected-bg', (event, path) => {
  // Actualizar UI con el fondo seleccionado
})
```

---

## 9. ALMACENAMIENTO PERSISTENTE

El proyecto usa **electron-store** para guardar configuraciones:

| Store | Proposito |
|-------|-----------|
| `aio-persist` | Datos globales (idioma, version FW, etc.) |
| `aio-data` | Configuracion de usuario (darkMode, etc.) |
| `aio-last` | Ultima compilacion |
| `user-themes` | Temas personalizados |
| `MZD_Speedometer` | Config del velocimetro |
| `casdk` | Apps CASDK instaladas |

**Ubicacion de archivos:**
- Windows: `%APPDATA%/MZD-AIO-TI/`
- macOS: `~/Library/Application Support/MZD-AIO-TI/`
- Linux: `~/.config/MZD-AIO-TI/`

---

## 10. TWEAKS DISPONIBLES

### Operaciones Principales (mainOps)
| ID | Nombre | Descripcion |
|----|--------|-------------|
| 0 | WiFi | Habilitar WiFi en CMU |
| 1 | Backup JCI | Crear backup del sistema |
| 2 | Custom Background | Fondo personalizado |
| 3 | Color Schemes | Esquemas de colores |
| 4 | SSH Bringback | Restaurar acceso SSH |
| 5 | SD Card ID | Obtener ID de tarjeta SD |
| 7 | Status Bar | Modificar barra de estado |
| 8 | Main Menu | Configurar menu principal |
| 9 | UI Style | Estilo de interfaz |

### Tweaks Individuales
- Android Auto
- Audio Order Modification
- Boot Animation
- Video Player
- Speedometer (en barra de estado)
- Remove Disclaimer
- Camera Warning Removal
- Menu Loops
- Date to Statusbar
- Fuel Consumption Tweak
- Y muchos mas...

---

## 11. CASDK - CUSTOM APPLICATION SDK

El proyecto incluye un SDK para crear aplicaciones personalizadas que corren en el CMU:

### Apps Incluidas:
- **app.2048** - Juego 2048
- **app.aio** - App informativa de AIO
- **app.speedometer** - Velocimetro digital
- **app.multicontroller** - Dashboard multiple
- **app.terminal** - Terminal de comandos
- **app.vdd** - Vehicle Data Display

### Estructura de una App CASDK:
```
app.miapp/
  +-- app.js              # Logica principal
  +-- app.css             # Estilos
  +-- index.html          # Vista
  +-- manifest.json       # Metadatos
```

---

## 12. CMU-AUTORUN - RECUPERACION

Sistema de scripts para recuperacion y testing:

- **ID7 Recovery** - Recuperar de errores
- **Auto WiFi** - WiFi automatico al boot
- **Auto ADB** - ADB automatico
- **Dryrun Mode** - Modo de prueba (no aplica cambios)
- **Serial Recovery** - Recuperacion por puerto serial

---

## 13. COMO HACER MODIFICACIONES

### Para agregar un nuevo tweak:

1. **Crear script de instalacion:**
   `app/files/tweaks/XX_mitweak-i.txt`

2. **Crear script de desinstalacion:**
   `app/files/tweaks/XX_mitweak-u.txt`

3. **Agregar opciones UI (opcional):**
   `app/opts/XXoptions.htm`

4. **Registrar en home.js:**
   Agregar a los arrays de opciones en el controlador

5. **Agregar archivos de config (si necesario):**
   `app/files/tweaks/config/mitweak/`

### Para modificar la UI:

1. **Vista principal:** `app/views/main.htm`
2. **Controlador:** `app/controllers/home.js`
3. **Estilos:** `app/assets/css/`

### Para modificar la compilacion:

1. **Motor:** `app/assets/js/build-tweaks.js`
2. **Utilidades CMU:** `app/files/tweaks/00_start.txt`

---

## 14. DEPENDENCIAS PRINCIPALES

### Runtime:
- electron: ^6.1.9
- electron-store: ^4.0.0
- electron-updater: ^4.2.0
- lodash: ^4.17.15
- drivelist: ^8.0.10 (deteccion USB)
- extract-zip: ^1.7.0
- xml2js: ^0.4.23

### Frontend:
- AngularJS 1.x
- jQuery 3.x
- Bootstrap 3.x
- Bootbox.js (dialogos)
- Featherlight (lightbox)

### Build:
- electron-builder: ^21.2.0

---

## 15. COMANDOS UTILES

```bash
# Instalar dependencias
npm install

# Ejecutar en desarrollo
npm start

# Compilar para Windows (64-bit)
npm run build:win64

# Compilar para macOS
npm run build:osx

# Compilar para Linux
npm run build:linux:x64
```

---

## 16. NOTAS IMPORTANTES

1. **El proyecto NO es un emulador** - Solo genera scripts de instalacion
2. **Los tweaks modifican el firmware real** - Pueden causar problemas si no se usan correctamente
3. **Siempre hacer backup** - Usar la opcion de backup antes de instalar
4. **Verificar compatibilidad** - No todos los tweaks funcionan en todas las versiones de firmware
5. **El sistema JCI usa Opera/WebKit** - Los archivos JS/CSS siguen estandares web

---

## 17. PROXIMOS PASOS RECOMENDADOS

Para tomar las riendas del proyecto:

1. **Ejecutar la app:** `npm start` y explorar la interfaz
2. **Leer 00_start.txt:** Entender las funciones base del CMU
3. **Estudiar un tweak simple:** Como touchscreen (01_touchscreen-i/u.txt)
4. **Modificar la UI:** Cambiar algo pequeno en main.htm
5. **Crear un tweak de prueba:** Usar dryrun mode para testing

---

*Documento generado para referencia de desarrollo*
*Basado en analisis del codigo fuente de MZD-AIO v2.8.6*
