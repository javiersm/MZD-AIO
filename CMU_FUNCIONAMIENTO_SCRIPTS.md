# COMO FUNCIONA EL CMU DEL MAZDA CONNECT Y COMO INICIA SCRIPTS

## Documento de Referencia - Sistema Operativo y Ejecucion de Scripts

---

## 1. QUE ES EL CMU

El **CMU (Connectivity Master Unit)** es la computadora central del sistema de infoentretenimiento Mazda Connect.

### Especificaciones Tecnicas:
- **Sistema Operativo:** Linux embedded (kernel 3.0.35)
- **Procesador:** ARM (i.MX6)
- **Framework UI:** JCI (Jaguar Connected Interface)
- **Motor de Renderizado:** Opera/WebKit
- **Sistema de Archivos:** SquashFS (solo lectura) + particiones escribibles

### Arquitectura del Sistema:
```
+------------------------------------------------------------------+
|                         CMU HARDWARE                              |
|                     (ARM i.MX6 Processor)                         |
+------------------------------------------------------------------+
|                                                                    |
|  +-------------------+  +-------------------+  +----------------+  |
|  | Linux Kernel      |  | JCI Framework     |  | Opera Browser  |  |
|  | (3.0.35)          |  | (UI/Apps)         |  | (Renderizado)  |  |
|  +-------------------+  +-------------------+  +----------------+  |
|                                                                    |
|  +-------------------+  +-------------------+  +----------------+  |
|  | D-Bus             |  | udev              |  | Watchdog       |  |
|  | (IPC)             |  | (Dispositivos)    |  | (Proteccion)   |  |
|  +-------------------+  +-------------------+  +----------------+  |
|                                                                    |
+------------------------------------------------------------------+
```

---

## 2. ESTRUCTURA DEL SISTEMA DE ARCHIVOS

### Particiones Principales:
```
/                           # Raiz (SquashFS, solo lectura por defecto)
/jci/                       # Framework JCI principal
  /gui/                     # Interfaz grafica
    /apps/                  # Aplicaciones nativas
    /common/js/Common.js    # Logica compartida (ARCHIVO CLAVE)
  /opera/                   # Motor de renderizado
    opera_dir/userjs/       # JavaScript personalizado
  /scripts/                 # Scripts del sistema
  /tools/                   # Herramientas (jci-dialog, etc)
  /version.ini              # Informacion de firmware

/tmp/mnt/                   # Punto de montaje para dispositivos
  /data/                    # Datos del sistema
  /data_persist/            # Datos persistentes (SOBREVIVE REBOOT)
    /dev/bin/               # UBICACION CLAVE PARA AUTORUN
      /autorun              # Script de autorun principal
      /02-*/                # Scripts de recuperacion
  /resources/               # Recursos adicionales
  /sd*/                     # USB/SD montados (sda, sdb, sdc, etc)

/config-mfg/                # Configuracion de fabrica
  /passwd                   # Archivo de usuarios
```

### Puntos de Montaje USB:
```
/tmp/mnt/sda    o  /tmp/mnt/sda1    # Primer USB
/tmp/mnt/sdb    o  /tmp/mnt/sdb1    # Segundo USB
/tmp/mnt/sdc    o  /tmp/mnt/sdc1    # Tercer USB
/mnt/sd_nav                          # Tarjeta SD de navegacion
```

---

## 3. PROCESO DE ARRANQUE DEL CMU

### Secuencia de Boot:

```
1. POWER ON
      |
      v
2. BOOTLOADER (U-Boot)
      |
      v
3. KERNEL LINUX (3.0.35)
      |
      v
4. INIT SCRIPTS
      |
      +---> Watchdog Service (proteccion contra cuelgues)
      +---> Servicios de sistema
      +---> D-Bus (comunicacion entre procesos)
      +---> udev (deteccion de dispositivos)
      |
      v
5. JCI FRAMEWORK
      |
      +---> /jci/scripts/start_normal_mode.sh
      +---> Opera Browser (carga UI)
      +---> Aplicaciones nativas
      |
      v
6. VERIFICACION DE AUTORUN
      |
      +---> Busca /tmp/mnt/data_persist/dev/bin/autorun
      +---> Si existe, lo ejecuta
      |
      v
7. SISTEMA LISTO
      |
      +---> Detecta USB insertados
      +---> Escucha eventos udev
```

---

## 4. SISTEMA UDEV - DETECCION DE USB

### Como el CMU Detecta un USB:

El sistema **udev** de Linux detecta cuando se inserta un dispositivo USB y ejecuta reglas.

### Regla de udev instalada:
**Archivo:** `/etc/udev/rules.d/99-run-tweaks.rules`
```bash
ACTION=="add",KERNEL=="sd[abcdef]*", RUN+="/bin/sh /tmp/mnt/data_persist/dev/bin/02-run-tweaks-from-usb/udev_add_action_handler.sh %k"
```

**Explicacion:**
- `ACTION=="add"` - Cuando se agrega un dispositivo
- `KERNEL=="sd[abcdef]*"` - Si es un dispositivo de almacenamiento (sda, sdb, etc)
- `RUN+=...` - Ejecuta el script handler con el nombre del dispositivo (%k)

### Flujo de Deteccion:
```
USB INSERTADO
      |
      v
KERNEL DETECTA DISPOSITIVO (sda1)
      |
      v
UDEV DISPARA REGLA 99-run-tweaks.rules
      |
      v
EJECUTA udev_add_action_handler.sh sda1
      |
      v
MONTA USB EN /tmp/mnt/sda1
      |
      v
BUSCA dataRetrieval_config.txt EN USB
      |
      v
LEE CMD_LINE= DEL ARCHIVO
      |
      v
EJECUTA EL COMANDO (ej: sh /mnt/sd*/tweaks.sh)
```

---

## 5. METODOS DE EJECUCION DE SCRIPTS

### Metodo 1: dataRetrieval_config.txt (Firmware Antiguo)

**Archivo en USB:** `dataRetrieval_config.txt`
```
CMU_STATUS=no
DATA_PERSIST=no
...
CMD_LINE=sh /mnt/sd*/tweaks.sh
```

El sistema busca este archivo y ejecuta lo que haya en `CMD_LINE=`.

**Como funciona:**
1. El CMU monta el USB
2. Busca `dataRetrieval_config.txt`
3. Extrae la linea `CMD_LINE=`
4. Ejecuta el comando

### Metodo 2: Autorun Scripts (Firmware Moderno v59+)

**Ubicacion permanente:** `/tmp/mnt/data_persist/dev/bin/autorun`

```bash
#!/bin/sh
# Script autorun principal

# Busca y ejecuta todos los archivos *.autorun
find `dirname $0` -iname \*.autorun -type f | sort | xargs -n 1 /bin/sh

# Busca run.sh en USB
for USB in a b c d e
do
    RUNSH="/tmp/mnt/sd${USB}/run.sh"
    if [ -e "${RUNSH}" ]; then
        /bin/sh "${RUNSH}"
        break
    fi
done
```

**Como funciona:**
1. Al boot, el CMU ejecuta `/tmp/mnt/data_persist/dev/bin/autorun`
2. Este busca archivos `*.autorun` y los ejecuta en orden alfabetico
3. Luego busca `run.sh` en cualquier USB conectado

### Metodo 3: cmu_dataretrieval.up (Actualizacion de Firmware)

El archivo `cmu_dataretrieval.up` es un archivo ZIP disfrazado que el CMU interpreta como una "actualizacion". Contiene instrucciones para ejecutar scripts.

**Estructura interna:**
```
cmu_dataretrieval.up (ZIP)
  +-- main_instructions.ini      # Instrucciones
  +-- retrieve_data/
      +-- execute.ini            # Script a ejecutar
      +-- e0000000001.dat        # Datos adicionales
  +-- versions.ini               # Version info
  +-- publisher_cert.pem         # Certificado (bypass seguridad)
```

---

## 6. FLUJO COMPLETO: DESDE AIO HASTA EL VEHICULO

### Paso 1: Compilacion en AIO (PC)
```
MZD-AIO (Desktop)
      |
      v
build-tweaks.js compila:
  - 00_intro.txt
  - 00_start.txt
  - [tweaks seleccionados]
  - 00_end.txt
      |
      v
Genera carpeta _copy_to_usb/
  +-- tweaks.sh              # Script maestro
  +-- dataRetrieval_config.txt
  +-- config/                # Archivos a copiar
```

### Paso 2: Copia a USB
```
Usuario copia _copy_to_usb/* a USB formateado FAT32
```

### Paso 3: Ejecucion en el Vehiculo
```
USB insertado en Mazda
      |
      v
CMU detecta USB via udev
      |
      v
Monta USB en /tmp/mnt/sda1
      |
      v
Lee dataRetrieval_config.txt
CMD_LINE=sh /mnt/sd*/tweaks.sh
      |
      v
Ejecuta tweaks.sh
      |
      v
tweaks.sh hace:
  1. Deshabilita Watchdog
  2. Monta / como lectura/escritura
  3. Detecta version firmware
  4. Verifica compatibilidad
  5. Crea backups (.org)
  6. Aplica modificaciones (sed, cp, etc)
  7. Muestra mensajes en pantalla
  8. Reinicia si es necesario
```

---

## 7. SCRIPT TWEAKS.SH - ESTRUCTURA

### Cabecera del Script:
```bash
#!/bin/sh

# Deshabilitar watchdog para evitar reinicios
echo 1 > /sys/class/gpio/Watchdog\ Disable/value

# Montar sistema de archivos como lectura/escritura
mount -o rw,remount /

# Variables de entorno
MYDIR=$(dirname $(readlink -f $0))
CMU_SW_VER=$(get_cmu_sw_version)
```

### Funciones Principales (00_start.txt):
```bash
# Obtener version de firmware
get_cmu_sw_version() {
  _ver=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/')
  echo "${_ver}"
}

# Verificar compatibilidad
compatibility_check() {
  # Verifica que el firmware sea compatible con el tweak
}

# Crear backup de un archivo
backup_org() {
  FILE="${1}"
  BACKUP_FILE="${1}.org"
  cp -a "${FILE}" "${BACKUP_FILE}"
}

# Restaurar archivo desde backup
restore_org() {
  FILE="${1}"
  BACKUP_FILE="${1}.org"
  cp -a "${BACKUP_FILE}" "${FILE}"
}

# Mostrar mensaje en pantalla del Mazda
show_message() {
  killall -q jci-dialog
  /jci/tools/jci-dialog --info --title="MZD-AIO" --text="$*" --no-cancel &
}
```

---

## 8. SISTEMA DE AUTORUN - INSTALACION PERMANENTE

### Que es Autorun:
Un mecanismo para ejecutar scripts automaticamente en cada boot.

### Ubicacion:
```
/tmp/mnt/data_persist/dev/bin/
  +-- autorun                    # Script principal
  +-- 02-run-tweaks-from-usb/    # Handler de USB
  |     +-- 99-run-tweaks.rules  # Regla udev
  |     +-- run-tweak-from-usb.sh
  |     +-- udev_add_action_handler.sh
  +-- 02-start-sshd-and-open-firewall/
  +-- 02-update-etc-passwd-if-needed/
  +-- 44-recovery-recovery/      # Scripts de recuperacion
```

### Script Autorun Principal:
```bash
#!/bin/sh
# /tmp/mnt/data_persist/dev/bin/autorun

# Busca y ejecuta todos los *.autorun en orden alfabetico
find `dirname $0` -iname \*.autorun -type f | sort | xargs -n 1 /bin/sh

# Busca run.sh en USB conectados
for USB in a b c d e
do
    RUNSH="/tmp/mnt/sd${USB}/run.sh"
    if [ -e "${RUNSH}" ]; then
        /bin/sh "${RUNSH}"
        break
    fi
done
```

### Archivos *.autorun:
Son scripts que se ejecutan en cada boot:
- `start-sshd-and-open-firewall.autorun` - Inicia SSH
- `passwd_update.autorun` - Actualiza usuarios
- `install-udev-handler-if-not-installed.autorun` - Instala handler USB

---

## 9. WATCHDOG - SISTEMA DE PROTECCION

### Que es el Watchdog:
Un temporizador hardware que reinicia el sistema si no recibe "pulsos" periodicamente. Protege contra cuelgues.

### Como Deshabilitarlo:
```bash
# Deshabilitar watchdog temporalmente
echo 1 > /sys/class/gpio/Watchdog\ Disable/value
```

**IMPORTANTE:** Si no se deshabilita antes de hacer modificaciones largas, el CMU se reiniciara automaticamente.

---

## 10. JCI-DIALOG - MOSTRAR MENSAJES

### Herramienta para mostrar dialogos:
```bash
# Mensaje informativo
/jci/tools/jci-dialog --info --title="Titulo" --text="Mensaje" --no-cancel &

# Pregunta con opciones
/jci/tools/jci-dialog --question --title="Titulo" --text="Pregunta?" \
  --ok-label="Si" --cancel-label="No"

# Dialogo de 3 botones
/jci/tools/jci-dialog --3-button-dialog --title="Titulo" --text="Texto" \
  --ok-label="Opcion1" --cancel-label="Opcion2" --button3-label="Opcion3"
```

**Nota:** `killall jci-dialog` antes de mostrar un nuevo mensaje.

---

## 11. D-BUS - COMUNICACION ENTRE PROCESOS

### Que es D-Bus:
Sistema de comunicacion entre procesos usado por el CMU.

### Socket D-Bus del CMU:
```
/tmp/dbus_hmi_socket
```

### Ejemplo - Deshabilitar restriccion de velocidad:
```bash
dbus-send --address=unix:path=/tmp/dbus_hmi_socket \
  /com/jci/testdiag com.jci.testdiag.DVD_SpeedRestriction_Enable boolean:false
```

---

## 12. VERSIONES DE FIRMWARE Y COMPATIBILIDAD

### Como se detecta la version:
**Archivo:** `/jci/version.ini`
```ini
JCI_SW_VER="59.00.502A-NA"
JCI_SW_VER_PATCH=""
JCI_SW_FLAVOR=""
```

### Grupos de compatibilidad:
```
COMPAT_GROUP=1: 55.00.XXX - 56.00.XXX (SSH abierto)
COMPAT_GROUP=2: 58.00.XXX
COMPAT_GROUP=3: 59.00.3XX
COMPAT_GROUP=4: 59.00.4XX
COMPAT_GROUP=5: 59.00.5XX (SSH bloqueado)
COMPAT_GROUP=6: 70.00.XXX
COMPAT_GROUP=7: 70.00.336+ (Mas reciente, muy bloqueado)
```

### Cambios importantes por version:
| Version | Cambio |
|---------|--------|
| < v56 | SSH abierto por defecto |
| v56+ | SSH bloqueado, necesita SSH Bringback |
| v59.00.502+ | Sistema bloqueado, necesita autorun |
| v70+ | Muy bloqueado, necesita conexion serial |

---

## 13. DIAGRAMA COMPLETO DEL FLUJO

```
+------------------+
|   AIO en PC      |
| (build-tweaks.js)|
+--------+---------+
         |
         | Genera
         v
+------------------+
|  _copy_to_usb/   |
|  +-- tweaks.sh   |
|  +-- config/     |
|  +-- dataRetrieval_config.txt
+--------+---------+
         |
         | Copia a USB
         v
+------------------+
|   USB FAT32      |
+--------+---------+
         |
         | Inserta en vehiculo
         v
+------------------+
|   CMU MAZDA      |
+--------+---------+
         |
    +----+----+
    |         |
    v         v
+-------+  +--------+
| udev  |  | Boot   |
| (USB) |  | Script |
+---+---+  +---+----+
    |          |
    v          v
+------------------+
| Detecta USB      |
| Lee dataRetrieval|
| config.txt       |
+--------+---------+
         |
         | CMD_LINE=sh /mnt/sd*/tweaks.sh
         v
+------------------+
| Ejecuta tweaks.sh|
+--------+---------+
         |
    +----+----+----+----+
    |    |    |    |    |
    v    v    v    v    v
+----+ +----+ +----+ +----+ +----+
|Dis | |Mon | |Bkup| |Mod | |Msg |
|Wdg | |R/W | |.org| |Arch| |Usr |
+----+ +----+ +----+ +----+ +----+
                          |
                          v
                   +------+------+
                   | SISTEMA     |
                   | MODIFICADO  |
                   +-------------+
```

---

## 14. COMANDOS UTILES PARA DEPURACION

### Via SSH al CMU:
```bash
# Ver version de firmware
cat /jci/version.ini

# Ver procesos
ps aux | grep jci

# Ver uso de memoria
free -m
cat /proc/meminfo

# Ver particiones
df -h
mount

# Ver logs
dmesg
cat /tmp/mnt/data/aio_logs/tweaks.log

# Reiniciar GUI sin reiniciar CMU
killall -9 jci

# Reiniciar CMU
reboot

# Montar sistema como escritura
mount -o rw,remount /

# Ver dispositivos USB
ls /tmp/mnt/
lsusb
```

---

## 15. ARCHIVOS CLAVE EN EL PROYECTO

| Archivo | Funcion |
|---------|---------|
| `cmu-autorun/installer/autorun` | Script autorun principal |
| `cmu-autorun/installer/tweaks.sh` | Instalador de autorun |
| `cmu-autorun/sdcard/recovery/*` | Scripts de recuperacion |
| `00_start.txt` | Funciones base para tweaks |
| `dataRetrieval_config.txt` | Trigger para ejecutar scripts |
| `99-run-tweaks.rules` | Regla udev para detectar USB |

---

## 16. RESUMEN

### Como el CMU inicia scripts:

1. **Metodo Antiguo (< v59):**
   - USB con `dataRetrieval_config.txt`
   - CMU lee `CMD_LINE=` y ejecuta

2. **Metodo Moderno (v59+):**
   - Scripts de autorun en `/tmp/mnt/data_persist/dev/bin/`
   - Se ejecutan en cada boot
   - Instalan regla udev para detectar USB
   - Cuando detectan USB, buscan `dataRetrieval_config.txt`
   - Ejecutan el comando en `CMD_LINE=`

3. **Metodo de Emergencia (v70+):**
   - Conexion serial al CMU
   - Instalar autorun manualmente
   - Luego funciona via USB

### Requisitos para ejecutar scripts:
1. Deshabilitar Watchdog
2. Montar / como lectura/escritura
3. Tener permisos de ejecucion
4. Archivo `dataRetrieval_config.txt` o `run.sh` en USB

---

*Documento generado para referencia de desarrollo*
*Basado en analisis del codigo fuente de MZD-AIO v2.8.6*
