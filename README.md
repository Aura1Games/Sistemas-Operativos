# Sistemas-Operativos
Respaldo de scripts de sistemas operativos del proyecto Sistema Gestor de Partidas de Draftosaurus

### Objetivos general del los scripts
Los scripts en el repositorio actual forman parte del contenido del serviodor que va a levantar la pagina web del proyecto curricular [S.I.G.P.D.](https://github.com/Aura1Games/Proyecto-Poke-Saurus), en el mismo se encuentra la manipulación de usuarios, grupos, firewallD, Docker y respaldos. 

### Distribución de los scripts

- Menu_abm.sh ( Punto de entrada de los scripts )
- |- `ABM_Usuarios.sh` ( Script de operaciónes CRUD de usuarios + agregar grupos a los usuarios)
- |- `ABM_Grupos.sh` ( Script  de opreaciónes CRUD de grupos - sin agregar grupos a los usuarios )
- |- `firewall.sh` ( Script CRUD de operaciónes del firewallD del sistema)
- |- `scriptRespaldos.sh` (Script de creación de resplados de la carpeta home del usuario proyecto)

#### Archivos de soporte 
- `config.sh` ( Script repositorio de funciónes usadas en ABM_Usuarios.sh y ABM_Grupos.sh )
- `configFirewall.sh` ( Script repositorio de funciónes usadas en firewall.sh )

#### Archivos de respaldos
###### /opt/script
- |- `scriptRespaldoFULL.sh` ( script de respaldos completos/full backup )
- |- `scriptRespaldoIncremental.sh` ( script de respaldos incrementales )
- |- `scriptRespaldoVolumenBD.sh` ( script de respaldo de volumen del contenedor BD )

#### Administración Docker
La administración de contenedores se encuentra dentro del archivo `Menu_abm.sh` el cual en el apartado `Administración de docker` del menú principal se puede:

- |- Levantar y apagar contenedor solo web (php:8-2apache con `docker run -d`)
- |- Levantar y apagar contenedor web-bd (`php:8-2apache` y `MySQL:8.0` con `docker compose up -d`)
- |- Consultar contenedores de docker (comando `docker ps -a`)
- |- Consultar volumenes de docker (comando `docker volume ls`)

#### Ejemplo de logs
###### /var/log/proyectoAura.log
Archivo con separación `-` en el cual usar el comando `awk` para obtener información por campos 
```bash
# Busca por logs de usuario, los registrados el día 08 
awk -F- '$7 == 08 && $2 == "usuario" {print $0}' /var/log/proyectoAura.log

```
