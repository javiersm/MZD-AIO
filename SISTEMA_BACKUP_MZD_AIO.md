# SISTEMA DE BACKUP EN MZD-AIO

## Documento de Referencia - Sistema de Copias de Seguridad

---

## 1. TIPOS DE BACKUP

Existen **dos tipos de backup** en el sistema:

### 1.1 BACKUP COMPLETO DE JCI (mainOps ID: 1)

Esta es la opcion que aparece en la interfaz como **"Backup JCI Folder"**.

**Archivo:** `app/files/tweaks/00_backup.txt`

**Que hace:**
```bash
# Crea una copia completa de /jci en el USB
BACKUPDIR=${MYDIR}/JCI-Backup    # MYDIR = carpeta del USB
cp -R /jci ${BACKUPDIR}          # Copia TODO el directorio /jci
```

**Resultado en el USB:**
```
USB/
  +-- JCI-Backup/
      +-- jci/                   # Copia completa del sistema JCI
      +-- jci.txt                # Metadata (fecha, version CMU, version AIO)
```

**Opciones:**
- `zipbackup: false` - Copia como carpeta (por defecto)
- `zipbackup: true` - Comprime a ZIP (`JCI-{version}.zip`)

---

### 1.2 BACKUP AUTOMATICO DE ARCHIVOS INDIVIDUALES (.org)

Este es el sistema **mas importante** y funciona automaticamente con cada tweak.

**Archivo:** `app/files/tweaks/00_start.txt` (funciones `backup_org()` y `restore_org()`)

**Como funciona:**

Antes de modificar cualquier archivo, el sistema crea una copia con extension `.org`:

```bash
# Ejemplo: Modificar Common.js
# ANTES de editar, backup_org() hace:
cp /jci/gui/common/js/Common.js /jci/gui/common/js/Common.js.org
```

---

## 2. FUNCION backup_org() - CREAR BACKUP

**Ubicacion:** `app/files/tweaks/00_start.txt` linea 183

```bash
backup_org()
{
  FILE="${1}"                              # Archivo a respaldar
  BACKUP_FILE="${1}.org"                   # Nombre del backup

  # Si ya existe backup, no hacer nada
  [ -e "${NEW_BKUP_FILE}" ] && return 0

  # Si no existe backup, crearlo
  if [ ! -e "${BACKUP_FILE}" ]
  then
    cp -a "${FILE}" "${BACKUP_FILE}"
    log_message "Created Backup of ${FILENAME} to ${BACKUP_FILE}"
  fi

  # Verificar que backup no este vacio
  [ ! -s "${BACKUP_FILE}" ] && v70_integrity_check

  # Guardar copia en USB si KEEPBKUPS=1
  if [ $KEEPBKUPS -eq 1 ]
  then
    cp "${BACKUP_FILE}" "${MYDIR}/bakups/"
  fi
}
```

**Flujo:**
```
1. Recibe ruta del archivo a modificar
2. Verifica si ya existe .org (no sobrescribe)
3. Crea copia: archivo.ext -> archivo.ext.org
4. Verifica que el backup no este vacio
5. Guarda copia en USB si KEEPBKUPS=1
```

---

## 3. FUNCION restore_org() - RESTAURAR BACKUP

**Ubicacion:** `app/files/tweaks/00_start.txt` linea 221

```bash
restore_org()
{
  FILE="${1}"                              # Archivo a restaurar
  BACKUP_FILE="${1}.org"                   # Backup a usar

  if [ -e "${BACKUP_FILE}" ]
  then
    if [ -s "${BACKUP_FILE}" ]             # Si backup no esta vacio
    then
      cp -a "${BACKUP_FILE}" "${FILE}"     # Restaurar
      log_message "Restored ${FILENAME} From Backup ${BACKUP_FILE}"
    else
      # Backup vacio, intentar reparar
      v70_integrity_check || return 1
    fi
    return 0
  else
    # Buscar en ubicacion secundaria (v70+)
    if [ -s "${NEW_BKUP_FILE}" ]
    then
      cp -a "${NEW_BKUP_FILE}" "${FILE}"
      return 0
    fi
    return 1
  fi
}
```

**Flujo:**
```
1. Busca archivo.ext.org
2. Si existe y no esta vacio:
   - Restaura: archivo.ext.org -> archivo.ext
3. Si esta vacio:
   - Usa v70_integrity_check() para reparar
4. Si no existe en ubicacion principal:
   - Busca en ubicacion secundaria (/resources para v70+)
```

---

## 4. FUNCION v70_integrity_check() - REPARAR BACKUPS

**Ubicacion:** `app/files/tweaks/00_start.txt` linea 265

Esta funcion verifica y repara backups corruptos o vacios en firmware v70+:

```bash
v70_integrity_check()
{
  # Solo para firmware v70
  if [ $COMPAT_GROUP -ne 6 ]
  then
    return 1
  fi

  # Buscar todos los archivos .org en /jci
  orgs=$(find /jci -type f -name "*.org")

  for i in $orgs; do
    # Si backup esta vacio o corrupto
    # Restaurar desde archivos de respaldo (fallback)
    # ubicados en config_org/v70/
  done
}
```

---

## 5. OPCIONES DE BACKUP EN LA UI

En el controlador `app/controllers/home.js`:

```javascript
$scope.user.backups = {
  org: true,              // Mantener archivos .org en el CMU
  test: true,             // Verificar instalacion despues
  skipconfirm: false,     // Saltar dialogos de confirmacion
  apps2resources: false   // Mover backups a /resources (v70+)
}
```

| Opcion | Default | Significado |
|--------|---------|-------------|
| `org` | true | Mantener archivos .org en el CMU |
| `test` | true | Verificar instalacion despues de aplicar |
| `skipconfirm` | false | Saltar dialogos de confirmacion |
| `apps2resources` | false | Mover backups a /resources (v70+) |

---

## 6. EJEMPLO PRACTICO: Tweak Touchscreen

### Instalacion (01_touchscreen-i.txt):
```bash
# 1. Crear backup automatico
backup_org "/jci/gui/common/js/Common.js"
# Resultado: /jci/gui/common/js/Common.js.org creado

# 2. Modificar archivo
sed -i 's/Global.AtSpeed/\/\/Global.AtSpeed/g' /jci/gui/common/js/Common.js
```

### Desinstalacion (01_touchscreen-u.txt):
```bash
# 1. Restaurar desde backup
restore_org "/jci/gui/common/js/Common.js"
# Resultado: Common.js.org -> Common.js (archivo original restaurado)
```

---

## 7. UBICACIONES DE BACKUPS

### En el CMU (vehiculo):
```
/jci/gui/common/js/Common.js.org     # Backup junto al original
/jci/opera/opera_home/opera.ini.org  # Otro ejemplo
/tmp/mnt/resources/aio/backups/      # Nueva ubicacion para v70+
```

### En el USB (si KEEPBKUPS=1):
```
USB/bakups/
  +-- Common.js.org
  +-- opera.ini.org
  +-- ... otros backups
```

---

## 8. VARIABLES IMPORTANTES

En `00_start.txt` se definen estas variables:

```bash
KEEPBKUPS=1        # 1 = Guardar backups en USB, 0 = No
TESTBKUPS=0        # 1 = Modo test (guarda antes/despues), 0 = Normal
APPS2RESOURCES=0   # 1 = Usar /resources para backups (v70+), 0 = Junto al original
NEW_BKUP_DIR="/tmp/mnt/resources/aio/backups"  # Ubicacion secundaria
```

---

## 9. FULL SYSTEM RESTORE

Si todo falla, existe la opcion de restauracion completa:

**En la UI:** `$scope.user.restore`

```javascript
$scope.user.restore = {
  full: false,        // Activar restauracion completa
  delBackups: false   // Eliminar backups despues de restaurar
}
```

**Que hace:**
1. Busca todos los archivos `.org` en el sistema
2. Restaura cada uno a su ubicacion original
3. Opcionalmente elimina los `.org` despues

---

## 10. RECOMENDACIONES PARA EMPEZAR

### Primera vez:
1. **Activa "Backup JCI Folder"** - Tendras copia completa en USB
2. **Deja `org: true`** (por defecto) - Cada archivo tendra su backup
3. **Usa `dryrun: true`** para probar - Ejecuta sin aplicar cambios

### Modo de prueba (Dryrun):
```javascript
$scope.user.autorun = {
  dryrun: true,  // Modo prueba - no modifica archivos reales
  // ...
}
```

### Verificar antes de instalar:
- Revisa el log de compilacion
- Verifica que tienes espacio en el USB
- Asegurate de tener la version de firmware correcta

---

## 11. ARCHIVOS RELACIONADOS

| Archivo | Funcion |
|---------|---------|
| `app/files/tweaks/00_start.txt` | Funciones backup_org(), restore_org() |
| `app/files/tweaks/00_backup.txt` | Backup completo de /jci |
| `app/controllers/home.js` | Opciones de backup en UI |
| `app/assets/js/build-tweaks.js` | Compilacion con variables de backup |

---

## 12. DIAGRAMA DE FLUJO

```
INSTALACION DE TWEAK
        |
        v
+------------------+
| backup_org()     |
| Crear .org       |
+------------------+
        |
        v
+------------------+
| Modificar        |
| archivo original |
+------------------+
        |
        v
    [EXITO]


DESINSTALACION DE TWEAK
        |
        v
+------------------+
| restore_org()    |
| Buscar .org      |
+------------------+
        |
    +---+---+
    |       |
 Existe   No existe
    |       |
    v       v
+-------+ +-------------+
|Restaur| |Buscar en    |
|ar .org| |/resources   |
+-------+ +-------------+
    |       |
    v       v
[EXITO]  [ERROR o EXITO]
```

---

*Documento generado para referencia de desarrollo*
*Basado en analisis del codigo fuente de MZD-AIO v2.8.6*
