# SISTEMA WIFI Y CONEXIONES REMOTAS EN MZD-AIO

## Documento de Referencia - Conectividad y Acceso Remoto al CMU

---

## 1. RESUMEN: PARA QUE SIRVE EL WIFI

El WiFi y las conexiones remotas en MZD-AIO sirven para:

1. **Acceso SSH remoto** - Conectarse al CMU via terminal para depuracion y modificaciones
2. **Android Auto Wireless** - Usar Android Auto sin cable USB
3. **Punto de Acceso (AP)** - El CMU crea su propia red WiFi para conectar dispositivos
4. **ADB sobre WiFi** - Android Debug Bridge para desarrollo
5. **WebSocket** - Comunicacion en tiempo real para apps CASDK
6. **Recuperacion** - Acceso de emergencia cuando el sistema falla

**El creador usaba estas conexiones para:**
- Depurar tweaks en tiempo real
- Probar modificaciones sin USB
- Desarrollar aplicaciones CASDK
- Recuperar sistemas bloqueados

---

## 2. HABILITAR WIFI EN EL CMU

### Archivo: `app/files/tweaks/00_wifi.txt`

**Problema:** En algunas regiones (Norteamerica), Mazda deshabilito el WiFi por defecto.

**Solucion:** El script modifica `syssettingsApp.js` para habilitar WiFi:

```bash
# Archivo que se modifica:
/jci/gui/apps/syssettings/js/syssettingsApp.js

# Cambio que hace:
# ANTES (WiFi bloqueado para Norteamerica):
if((region != (framework.localize.REGIONS['NorthAmerica']) ...))

# DESPUES (WiFi habilitado para todos):
if(true)
```

**Resultado:** La opcion de WiFi aparece en el menu de configuracion del Mazda.

---

## 3. SSH BRINGBACK - ACCESO REMOTO POR TERMINAL

### Archivo: `app/files/tweaks/00_sshbringback.txt`

### 3.1 Que es SSH Bringback

En firmwares v56+ Mazda desactivo el acceso SSH por seguridad. Este tweak lo restaura.

### 3.2 Como funciona

```bash
# 1. Modifica el firewall para permitir SSH
cp -a ${MYDIR}/config/ssh_bringback/jci-fw.sh /jci/scripts

# 2. Actualiza usuarios y contrasenas
cp -a ${MYDIR}/config/ssh_bringback/passwd /tmp
cp -a ${MYDIR}/config/ssh_bringback/sshd_config /etc/ssh

# 3. Ejecuta script de actualizacion
/tmp/passwd_update.sh
```

### 3.3 Credenciales de acceso

**Archivo:** `config/ssh_bringback/passwd`

| Usuario | Password | Descripcion |
|---------|----------|-------------|
| `cmu` | `jci` | Usuario principal (root) |
| `jci` | `jci` | Usuario alternativo (root) |
| `user` | (vacio) | Usuario temporal |
| `root` | (vacio) | Solo en FW antiguos |

### 3.4 Puertos SSH abiertos

**Archivo:** `config/ssh_bringback/sshd_config`

```
Port 22      # Puerto SSH estandar
Port 24000   # Puerto alternativo 1
Port 36000   # Puerto alternativo 2
```

### 3.5 Configuracion del Firewall

**Archivo:** `config/ssh_bringback/jci-fw.sh`

```bash
# Permite conexiones SSH en multiples puertos
$IPTABLES -A INPUT -p tcp -m multiport --destination-ports 22,24000,36000 \
  -m state --state NEW,ESTABLISHED -j ACCEPT

# Permite DHCP en wlan0 (para WiFi AP)
$IPTABLES -A INPUT -p udp -i wlan0 --sport 68 --dport 67 -j ACCEPT

# Permite DNS en wlan0
$IPTABLES -A INPUT -p udp -i wlan0 --dport 53 -m state --state NEW -j ACCEPT
```

---

## 4. WIFI ACCESS POINT (AP) - CMU COMO ROUTER

### Archivo: `cmu-autorun/sdcard/recovery-extra/02-start-wifiAP/jci-wifiap.sh`

### 4.1 Que hace

El CMU puede crear su propia red WiFi a la que te conectas desde tu telefono/laptop.

### 4.2 Configuracion de red

```bash
NETWORK_INTERFACE_NAME=wlan0
NETWORK_IP_ADDRESS=192.168.53.1      # IP del CMU
NETWORK_MASK=255.255.255.0
DHCP_START_ADDRESS=192.168.53.20     # Rango de IPs para clientes
DHCP_END_ADDRESS=192.168.53.254
```

### 4.3 Configuracion del AP

```bash
# Archivo: hostapd.conf (generado dinamicamente)
interface=wlan0
driver=nl80211
channel=9              # Canal WiFi
hw_mode=g              # 802.11g
wpa=2                  # WPA2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=XXXXX   # Password configurado por usuario
rsn_pairwise=CCMP      # Encriptacion AES
ssid=CMU-XXXXXX        # Nombre de la red
```

### 4.4 Comandos disponibles

```bash
jci-wifiap.sh start    # Iniciar AP
jci-wifiap.sh stop     # Detener AP
jci-wifiap.sh restart  # Reiniciar AP
jci-wifiap.sh status   # Ver estado
```

### 4.5 Como conectarse

1. El CMU crea red WiFi (ej: `CMU-XX:XX:XX`)
2. Te conectas desde tu laptop/telefono
3. Tu dispositivo recibe IP en rango 192.168.53.20-254
4. Accedes al CMU en `192.168.53.1`

```bash
# Desde tu laptop:
ssh cmu@192.168.53.1 -p 22
# Password: jci
```

---

## 5. ADB - ANDROID DEBUG BRIDGE

### 5.1 ADB sobre USB

**Archivo:** `cmu-autorun/sdcard/adb/adb.sh`

Permite conectar un telefono Android y usar SSH a traves de el:

```bash
# 1. Conecta Android al puerto USB del Mazda
# 2. El CMU detecta el dispositivo
adb wait-for-device

# 3. Crea tunel inverso para SSH
adb reverse tcp:2222 tcp:22

# 4. Desde el Android puedes hacer:
ssh cmu@localhost -p 2222
# Password: jci
```

### 5.2 SSH sobre ADB

**Archivo:** `cmu-autorun/sdcard/recovery-extra/02-start-adb/ssh-over-adb.sh`

```bash
#!/bin/sh
adb start-server
adb wait-for-device
adb reverse tcp:2222 tcp:22    # Mapea puerto 2222 del Android al 22 del CMU

# Ahora desde una app de terminal en Android:
# ssh cmu@localhost -p 2222
```

### 5.3 Para que sirve

- **Recuperacion de emergencia** cuando no hay WiFi
- **Depuracion** de aplicaciones
- **Acceso SSH** sin necesidad de WiFi

---

## 6. ANDROID AUTO WIRELESS

### Archivo: `app/files/tweaks/25_androidautowifi-i.txt`

### 6.1 Que hace

Permite usar Android Auto sin cable USB, via WiFi.

### 6.2 Configuracion

**Archivo:** `config/androidautowifi/headunit.json`

```json
{
  "launchOnDevice": true,
  "carGPS": true,
  "wifiTransport": true,        // Habilita WiFi
  "phoneIpAddress": "192.168.43.1",  // IP del telefono
  "reverseGPS": false
}
```

### 6.3 Como funciona

1. El telefono crea hotspot WiFi
2. El CMU se conecta al hotspot
3. Android Auto funciona via WiFi

---

## 7. WEBSOCKET - COMUNICACION EN TIEMPO REAL

### 7.1 Que es

WebSocket permite comunicacion bidireccional entre apps CASDK y el sistema.

### 7.2 Como se usa

```bash
# Inicia servidor WebSocket en puerto 9998
/jci/gui/addon-common/websocketd --port=9998 sh &
```

### 7.3 Para que sirve

- Apps CASDK se comunican con el sistema
- Video player envia comandos
- Speedometer recibe datos en tiempo real

---

## 8. CONEXION SERIAL - RECUPERACION DE EMERGENCIA

### Archivo: `app/views/serial.html`

### 8.1 Cuando se necesita

En FW v59.00.502+ el CMU esta bloqueado y no permite tweaks via USB.
La unica forma de desbloquear es via conexion serial.

### 8.2 Equipamiento necesario

- **USB a TTL Serial Adapter** (CP2102) - ~$6
- **Cables** - TX, RX, GND
- **Putty** o **SecureCRT** - Terminal serial
- **Llave 10mm** - Para extraer el CMU

### 8.3 Conexiones fisicas

```
CMU (conector "power&more"):
+---+---+
| 2S| 2T|   2S = RX del CMU (conectar a TX del adaptador)
+---+---+   2T = TX del CMU (conectar a RX del adaptador)
            GND = Cualquier tornillo del CMU

Adaptador CP2102:
+-----+-----+-----+
| TX  | RX  | GND |
+-----+-----+-----+
  |      |     |
  v      v     v
 2S     2T   Tornillo
(CMU)  (CMU)  (CMU)
```

### 8.4 Configuracion del terminal

```
Puerto: COM# (ver en Administrador de dispositivos)
Baud Rate: 115200
Data Bits: 8
Parity: None
Stop Bits: 1
```

### 8.5 Comandos de recuperacion

```bash
# 1. Login
user
jci

# 2. Copiar archivos de recuperacion desde USB
cp -r /mnt/sd*/XX/* /mnt/data_persist/dev/bin/
chmod +x /mnt/data_persist/dev/bin/autorun
/mnt/data_persist/dev/bin/autorun

# 3. Verificar
ls -l /mnt/data_persist/dev/bin
```

### 8.6 Despues de la recuperacion

Una vez instalados los scripts de autorun:
- Puedes instalar tweaks via USB normalmente
- SSH funciona con usuario `cmu` password `jci`

---

## 9. OPCIONES EN LA UI

### En `$scope.user.autorun`:

```javascript
$scope.user.autorun = {
  installer: false,    // Instalar scripts de autorun
  id7recovery: false,  // Scripts de recuperacion ID7
  autoWIFI: false,     // Iniciar WiFi AP automaticamente
  autoADB: false,      // Iniciar ADB automaticamente
  dryrun: false,       // Modo prueba (no aplica cambios)
  serial: false        // Modo recuperacion serial
}
```

---

## 10. DIAGRAMA DE CONEXIONES

```
+------------------+
|    TU LAPTOP     |
|  192.168.53.100  |
+--------+---------+
         |
         | WiFi
         v
+------------------+
|   CMU (WiFi AP)  |
|   192.168.53.1   |
|                  |
|  SSH: puerto 22  |
|  SSH: puerto 24000|
|  SSH: puerto 36000|
|  WebSocket: 9998 |
+--------+---------+
         |
         | USB
         v
+------------------+
|  TELEFONO ANDROID|
|  (ADB reverse)   |
|  localhost:2222  |
+------------------+
```

---

## 11. FLUJO DE CONEXION TIPICO

### Opcion A: WiFi AP (mas comun)

```
1. Instalar SSH Bringback + WiFi via USB
2. CMU reinicia con WiFi habilitado
3. En el menu del Mazda: Configuracion > WiFi > Crear AP
4. Desde laptop: conectar a red WiFi del CMU
5. ssh cmu@192.168.53.1 -p 22
6. Password: jci
7. Ya tienes acceso root al CMU
```

### Opcion B: ADB (sin WiFi)

```
1. Instalar ADB scripts via USB
2. Conectar Android al USB del Mazda
3. En Android: abrir app de terminal
4. ssh cmu@localhost -p 2222
5. Password: jci
6. Ya tienes acceso root al CMU
```

### Opcion C: Serial (recuperacion)

```
1. Extraer CMU del vehiculo
2. Conectar cables TX/RX/GND
3. Abrir Putty, configurar COM port
4. Ejecutar comandos de recuperacion
5. Reinstalar CMU
6. Ahora puedes usar USB normalmente
```

---

## 12. CASOS DE USO

### Desarrollo de tweaks
```bash
# Conectar via SSH
ssh cmu@192.168.53.1

# Editar archivos en tiempo real
vi /jci/gui/common/js/Common.js

# Ver logs
tail -f /tmp/mnt/data/aio_logs/tweaks.log

# Reiniciar GUI sin reiniciar CMU
killall -9 jci
```

### Depuracion
```bash
# Ver procesos
ps aux | grep jci

# Ver uso de memoria
free -m

# Ver sistema de archivos
df -h

# Ver logs del sistema
dmesg
```

### Desarrollo de apps CASDK
```bash
# Ver apps instaladas
ls /tmp/mnt/resources/aio/mzd-casdk/apps/

# Reiniciar app
pkill -f websocketd
/jci/gui/addon-common/websocketd --port=9998 sh &
```

---

## 13. ARCHIVOS RELACIONADOS

| Archivo | Funcion |
|---------|---------|
| `00_wifi.txt` | Habilita WiFi en menu |
| `00_sshbringback.txt` | Restaura acceso SSH |
| `config/ssh_bringback/` | Archivos de configuracion SSH |
| `jci-wifiap.sh` | Script para crear AP |
| `adb.sh` | ADB sobre USB |
| `ssh-over-adb.sh` | SSH via ADB |
| `serial.html` | Instrucciones conexion serial |

---

## 14. SEGURIDAD

### Credenciales por defecto:
- Usuario: `cmu` o `jci`
- Password: `jci`

### Puertos abiertos:
- 22, 24000, 36000 (SSH)
- 9998 (WebSocket)
- 67 (DHCP)
- 53 (DNS)

### Recomendaciones:
1. Cambiar password despues de instalar
2. No dejar WiFi AP activo permanentemente
3. Usar solo en redes de confianza

---

## 15. RESUMEN RAPIDO

| Metodo | Requisitos | IP/Puerto |
|--------|------------|-----------|
| WiFi AP | SSH Bringback + WiFi | 192.168.53.1:22 |
| ADB | Android + USB | localhost:2222 |
| Serial | Cables TX/RX/GND | COM:115200 |

**Password universal:** `jci`

---

*Documento generado para referencia de desarrollo*
*Basado en analisis del codigo fuente de MZD-AIO v2.8.6*
