#!/bin/bash

mostrar_input_dialog() { # Función para mostrar dialogs sin repetir código
texto="$1"
placeholder="$2"
dialog --erase-on-exit --no-shadow --no-cancel --stdout --inputbox "$texto" 9 40 "$placeholder"
}

mostrar_msg-title_dialog() { # Función para mostrar dialogs sin repetir código
texto="$1"
titulo="$2"
dialog --erase-on-exit --no-shadow --no-cancel --title "$titulo" --msgbox "$texto" 10 40
}
mostrar_msg_timeout() {
dialog --clear --no-shadow --erase-on-exit --no-cancel --timeout 5 \
 --title "$2" --msgbox "$1" 10 40
}

mostrar_msg_dialog() { # Función para mostrar dialogs sin repetir código
texto="$1"
dialog --no-shadow --no-cancel --msgbox "$texto" 10 45
}

verificar_sudoer() {
    if [[ $EUID -eq 0 ]]; then
        return 0  # Es root o sudo
    else
        read -p "$(whoami) no tienes permisos de administrador. Presiona Enter para salir..."
        exit 1
    fi
}

verificar_servicio() {
    local servicio=$1
    if [ -z "$servicio" ]; then
        mostrar_msg_dialog "Error: Nombre de servicio vacío"
        return 2
    fi

    	if firewall-cmd --get-services | grep -qw "$servicio"; then # grep -w busca coincidencias totales con el servicio
      	  return 0
    	else
          return 1
    	fi

}


listar_servicios() {
    while true; do
        ingreso=$(dialog --stdout --no-cancel --no-shadow --title "Opciones servicios" --menu \
        "Ingrese una opción" 12 33 6 \
        1 "Listar servicios" \
        2 "Buscar servicios" \
	3 "Ver servicios disponibles" \
        X "Salir")

        case $ingreso in
            1)
                # tr reemplaza los espacios en blanco por un salto de línea y sort ordena alfabeticamente
                lista_servicios=$(firewall-cmd --get-services | tr ' ' '\n' | sort)
                mostrar_msg_dialog "$lista_servicios"
                ;;
            2)
                ingreso=$(dialog --no-shadow --stdout --clear --inputbox "Ingrese el servicio a buscar" 8 30 "mysql")
                if [ -n "$ingreso" ]; then
                    if firewall-cmd --get-services | grep -qw "$ingreso"; then
                        mostrar_msg_dialog "$(firewall-cmd --info-service=$ingreso)"
                    else
                        mostrar_msg_dialog "Servicio no encontrado"
                    fi
                else
                    # Si el usuario presiona Cancel o no ingresa nada, vuelve al menú
                    continue
                fi
                ;;
	    3) mostrar_msg_dialog "$(firewall-cmd --list-services | tr ' ' '\n')"
		;;
            X)
		return 0
                ;;
        esac
    done
}


agregar_servicio() {
    local serviAcio=$1
    if verificar_servicio "$servicio"; then
       if ! firewall-cmd --permanent --list-services | grep -qw "$servicio"; then

	  if firewall-cmd --add-service="$servicio" --permanent; then
              firewall-cmd --reload
              mostrar_msg_dialog "Servicio $servicio agregado permanentemente"
          else
              mostrar_msg_dialog "Error: No se pudo agregar el servicio $servicio"
              return 1
          fi

       else
	mostrar_msg_dialog "Servicio ya agregado"
       fi
    else
        mostrar_msg_dialog "El servicio $servicio no está diponible o no existe"
        return 1
    fi
}

eliminar_servicio() {
local servicio=$1
 if verificar_servicio "$servicio"; then

     if sudo firewall-cmd --permanent --list-services | grep -qw "$servicio"; then

	if firewall-cmd --remove-service="$servicio" --permanent; then # verifica si el comando se ejecutó con exito
 	  firewall-cmd --reload # Reinicia el firewall para que se aplique de forma permanente
 	  mostrar_msg_dialog "Servicio $servicio removido permanentemente"
	else
	  mostrar_msg_dialog "Error: No se pudo remover el servicio $servicio"
          return 1
 	fi
     else
	mostrar_msg_dialog "El servicio $servicio no está en el sistema"
     fi
 else
        mostrar_msg_dialog "Error: El servicio $servicio no existe"
 fi
}

listar_interfaces() {
mostrar_msg-title_dialog "$(sudo firewall-cmd --get-active-zones | awk -F: ' $1 = \"interfaces\" {print $2}') " "Interfaces de red disponibles"
}
mostrar_zonas_activas() {
mostrar_msg-title_dialog "$(sudo firewall-cmd --get-active-zones)" "ZONAS ACTIVAS"
}

zonas_disponibles() {
mostrar_msg-title_dialog "$(sudo firewall-cmd --get-zones | tr ' ' '\n')" "ZONAS DISPONIBLES"
}

verificar_zona() {
local zona="$1"
if [ -z "$zona" ]; then
return 1
fi

if sudo firewall-cmd --get-zones | grep -qw "$zona"; then
return 0
else
return 1
fi
}


listar_datos_zonas() {
zona="$1"
if verificar_zona "$zona"; then
mostrar_msg-title_dialog "$(firewall-cmd --list-all --zone=$zona --permanent)" "DATOS DE LA ZONA $zona"
else
mostrar_msg-title_dialog "Zona no encontrada en el sistema" "ERROR"
fi
}

verificar_interfaces() {
local interfaz="$1"
if [ -z "$interfaz" ]; then
return 1
fi

if sudo firewall-cmd --get-active-zones | awk -F: ' $1 = "interfaces" {print $2}' | grep -qw "$interfaz";then
return 0
else
return 1
fi
}

cambiar_interfaces_de_zona() {
local interfaz="$1"
local zona="$2"
if verificar_interfaces "$interfaz"; then

if verificar_zona "$zona"; then
if sudo firewall-cmd --permanent --change-interface="$interfaz" --zone="$zona"; then
sudo firewall-cmd --reload
mostrar_msg_dialog "Interfaz agregada con éxito"
else
mostrar_msg-title_dialog "No se pudo cambiar la interfaz $interfaz a la zona $zona" "ERROR"
fi
else
mostrar_msg-title_dialog "La zona $zona no existe" "ERROR"
fi

else
mostrar_msg-title_dialog "La interfaz $interfaz no existe" "ERROR"
fi
}

cambiar_zona_d() {
local zona="$1"
if verificar_zona "$zona"; then
    if sudo firewall-cmd --set-default-zone="$zona"; then
	mostrar_msg_dialog "Zona $zona seteada como zona default" "ZONAS"
    	listar_datos_zonas "$zona"
    else
	mostrar_msg_dialog "No se pudo setear la zona $zona como default" "ERROR"
    fi
else
mostrar_msg_dialog "Debes de ingresar una zona" "ERROR"
fi
}

verificar_puertos() {
local puerto="$1"
local puertoNumero=$(echo "$puerto" | awk -F/ '{print $1}') # obtiene el numero sin el protocolo del puerto dado
if sudo firewall-cmd --list-ports --permanent | tr ' ' '\n' | awk -F/ '{print $1}' | grep -qw "$puertoNumero"; then
  return 0
else
  return 1
fi
}

listar_puertos() {
local puertos=$(sudo firewall-cmd --list-ports --permanent | tr ' ' '\n \n')
echo "$puertos"
}

AgergarPuertos() {
local puerto="$1"
if [ -z "$puerto" ]; then
  mostrar_msg-title_dialog "Debes de ingresar un puerto no vacío" "ERROR"
  return 2
fi
if ! verificar_puertos "$puerto"; then
  if sudo firewall-cmd --permanent --add-port="$puerto"; then
    sudo firewall-cmd --reload
    mostrar_msg_dialog "Puerto $puerto agregado con éxito"
    mostrar_msg_timeout "$(listar_puertos)" "PUERTOS EN EL SISTEMA"
  else
    mostrar_msg_dialog "Error al agregar el puerto"
    mostrar_msg_timeout "Error común: recurda colocar el protocolo después del puerto ej: 22/tcp" "ADVERTENCIA"
  fi
else
mostrar_msg_dialog "El puerto $puerto está en uso"
fi
}

EliminarPuertos() {
local puerto="$1"
if [ -z "$puerto" ]; then
  mostrar_msg-title_dialog "Debes de ingresar un puerto no vacío" "ERROR"
  return 2
fi
if verificar_puertos "$puerto"; then # Verifica que el puerto exista en el sistema

  if sudo firewall-cmd --permanent --remove-port="$puerto"; then
    sudo firewall-cmd --reload
    mostrar_msg_dialog "Puerto $puerto eliminado con exito"
    mostrar_msg_timeout "$(listar_puertos)" "PUERTOS EN EL SISTEMA"
  else
    mostrar_msg_dialog "Error al eliminar el puerto"
    mostrar_msg_timeout "Error común: recurda colocar el protocolo después del puerto ej: 22/tcp" "ADVERTENCIA"
  fi
else
mostrar_msg-title_dialog "PUERTO $puerto DENTRO DE UN RANGO o INEXISTENTE \n Los puertos que estén dentro de un rango no se tendrán en cuenta en la busqueda de puertos" "Fallo en la busqueda de $puerto"

fi

}
# Función para verificar si una cadena es una IP válida.
validar_ip_simple() {
    local ip_a_validar=$1
    local num_puntos
    local octeto

    # 1. Contar el número de puntos
    num_puntos=$(echo "$ip_a_validar" | grep -o '\.' | wc -l)

    # Si no hay exactamente 3 puntos, no es una IP.
    if [[ "$num_puntos" -ne 3 ]]; then
        return 1
    fi

    # 2. Leer los octetos en un array
    IFS='.' read -ra octetos <<< "$ip_a_validar"

    # 3. Iterar sobre los octetos y validar el rango
    for octeto in "${octetos[@]}"; do
        # Asegurarse de que el octeto no esté vacío
        if [[ -z "$octeto" ]]; then
            return 1
        fi
        # Verificar que el octeto es un número y está en el rango 0-255
        if [[ "$octeto" -lt 0 || "$octeto" -gt 255 ]]; then
            return 1
        fi
    done

    # Si todo es correcto, la IP es válida.
    return 0
}

gestion_ssh() {
# deberá de consultar si desea que se aplique se forma permanente o runtime
while true; do
local ingreso=$(dialog --erase-on-exit --stdout --title "MANIPULACIÓN DE SSH" --no-cancel --menu "LOS CAMBIOS SE HARÁN EN LA ZONA DEFAULT DE QUERER CAMBIARLA PODRÁS HACERLO EN EL MENU DE ZONAS" 15 53 6 \
1 "Consultar estado de SSH" \
2 "Encender SSH" \
3 "Apagar SSH" \
4 "Bloquear ssh" \
5 "Bloquear IP para SSH" \
6 "Reiniciar firewalld" \
X "Salir")

case $ingreso in
1)
dialog --title "¿Ver información permanente de ssh?" --yesno "Si para aceptar | no para información RunTime" 7 55
if [ $? -eq 0 ]; then # si ingresa SI
  mostrar_msg-title_dialog "STATUS: \n $(systemctl status sshd | sed -n '5p') \n \n INFO: \n $(firewall-cmd --info-service=ssh --permanent)" "INFORMACIÓN PERMANENTE DE SSH"
else # si ingresa NO
mostrar_msg-title_dialog "STATUS: \n $(systemctl status sshd | sed -n '5p') \n \n INFO: \n $(firewall-cmd --info-service=ssh)" "INFORMACIÓN RUNTIME DE SSH"
fi
;;
2)
 sudo systemctl start sshd && mostrar_msg_timeout "Servicio ssh encendido correctamente" "OPERACIÓN EXITOSA"
;;
3)
sudo systemctl stop sshd && mostrar_msg_timeout "Servicio ssh apagado con éxito"
;;
4)
dialog --title "¿bloquear de forma permanente SSH?" --yesno "Si para aceptar | no para bloquear en RunTime" 7 55
if [ $? -eq 0 ]; then # si ingresa SI
   sudo firewall-cmd --permanent --remove-service=ssh && mostrar_msg_timeout "Servicio ssh bloqueado permanentemente" "OPERACIÓN EXITOSA"
else # si ingresa NO
   sudo firewall-cmd --remove-service=ssh && mostrar_msg_timeout "Servicio ssh agregado en RunTime" "OPERACIÓN EXITOSA"
fi
;;
5)
local IP=$(mostrar_input_dialog "Ingrese una IP a bloquear ssh" "192.168.X.X")

if validar_ip_simple "$IP"; then
  sudo firewall-cmd --permanent --add-rich-rule="rule family=\"ipv4\" source address=\"$IP\" service name=\"ssh\" reject"
else
    mostrar_input_dialog "IP no valida"
fi
;;
6)
sudo firewall-cmd --reload && mostrar_msg_timeout "Se reinició el firewall con éxito" ""
;;
X)dialog --erase-on-exit --yesno "¿Realmente quieres salir?" 6 30
   [ $? -eq 0 ] && break
;;
esac
done


}

verificarIPreglas() {
local IP=$1
# lista las reglas de firewalld, las separa por renglones y busca una ip que coincida con las ips de las reglas
local comando=$(sudo firewall-cmd --permanent --list-rich-rules | tr ' ' '\n' |awk -F= '$1!="family" && $1!="name" {print $2}' |
grep -qw "$IP")
if $comando; then
return 0
else
return 1
fi
}

listarReglas() {
local comando=$(sudo firewall-cmd --list-rich-rules)
echo "$comando"
}

consultarReglas() {
local comando=$(listarReglas)
[ -z "$comando" ] && comando="No hay reglas enriquecidas para la zona $(sudo firewall-cmd --get-default-zone)"
dialog --title "Reglas de firewalld de la zona $(sudo firewall-cmd --get-default-zone)" --no-cancel --msgbox "$comando" 10 80
}

consultarIPReglas() {
local ingreso=$(mostrar_input_dialog "Ingrese la IP a consultar" "192.168.1.60")
if validar_ip_simple $ingreso; then
  local comandoregla=$(sudo firewall-cmd --permanent --list-rich-rules | grep -w "$ingreso")
  [ -z "$comandoregla" ] && comandoregla="La IP $ingreso no está en las rich rules"
  mostrar_msg_dialog "$comandoregla"
else
  mostrar_msg_dialog "la ip $ingreso no es una ip valida"
fi
}

PermitirIPreglas() {

mostrar_msg-title_dialog "La siguiente operación tendrá como objeto permitir el trafico de red solo por la ip dada por el usuario a un servicio, es decir que el servicio que el usuario ingrese solo será accesible por la IP dada" "| ATENCION |"
[ $? -ne 0 ] && return 1
IP=$(mostrar_input_dialog "Ingrese una IP" "")

# Verificación de la IP
 if ! validar_ip_simple $IP; then
    mostrar_msg_dialog "La ip $IP no es una ip valida"
    return 1
 fi
# Ingresar servicio para habilitar solo por la ip dada
 local servicio=$(mostrar_input_dialog "Ingrese el servicio a habilitar por ip" "ssh")

# Verificar servicio
if ! verificar_servicio $servicio; then
 mostrar_msg_dialog "el servicio $servicio no es un servicio disponible"
 return 1
fi

# ejecutar operación
# los escapados \ le dicen a bash que la siguiente comilla no es el fin del string
# bash solo expande las variables que están entre comillas dobles, por lo tanto requiere que se usen para no lanzar errores comillas simples
sudo firewall-cmd --permanent --remove-service="$servicio"
sudo firewall-cmd --permanent --add-rich-rule="rule priority=100 family=ipv4 source address=\"$IP\" service name=\"$servicio\" accept"
if [ $? -eq 0 ]; then
 if ! grep -qw "rule priority=10000 family=\"ipv4\" service name=\"$servicio\" reject" listarReglas; then
   sudo firewall-cmd --permanent --add-rich-rule="rule priority=10000 family=\"ipv4\" service name=\"$servicio\" reject"
 fi
  sudo firewall-cmd --reload
# Mensaje de éxito
mostrar_msg-title_dialog "Se agregó la ip $IP al servicio $servicio \n Ahora el trafico para el servicio $servicio solo será disponible por la ip $IP" "OPERACIÓN EXITOSA"
mostrar_msg_dialog "El servicio $servicio fué removido permanentemente, si quieres consultar su estado o agregarlo nuevamente consulta el apartado de servicios en opciones de firewall"
else
mostrar_msg_dialog "Error al agregar regla enriquecida, codigo de error: $?"
fi
}

eliminarRegla() {
dialog --erase-on-exit --clear --no-shadow --title " | ATENCIÓN |" --msgbox \
"Esta operación eliminará una rich rule de firewalld según el servicio e IP que indiques." 8 60
[ $? -ne 0 ] && return 1

dialog --no-shadow --title "Reglas disponibles" --msgbox "$(listarReglas)" 30 80
[ $? -ne 0 ] && return 1
# Pedir la IP
IP=$(mostrar_input_dialog "Ingrese la IP asociada a la regla a eliminar \n De querer eliminar una regla para todas las IPs ingrese NINGUNA" "")



if [[ "$IP" = "NINGUNA" ]]; then
  mostrar_msg_dialog "La regla a eliminar será reject por defecto."
  local servicio=$(mostrar_input_dialog "Ingrese el servicio asociado a la regla" "ssh")

  # Verificamos que el servicio en verdad existe
  if ! verificar_servicio $servicio; then
      mostrar_msg_dialog "El servicio $servicio no es válido o no está disponible"
      return 1
  fi
  # Armamos la regla
  local regla="rule priority=10000 family=\"ipv4\" service name=\"$servicio\" reject"

  # Verificamos la regla
  if grep -qw "$regla" listarReglas; then
    mostrar_msg-title_dialog "La regla anterior dictada no existe, asegurate de que los datos sean correctos"
    return 1
  fi
  # Ejecutamos la regla
  if sudo firewall-cmd --permanent --remove-rich-rule="$regla"; then
    mostrar_msg_dialog "Se eliminó correctamente la regla reject para el servicio $servicio"
    sudo firewall-cmd --reload
  else
    mostrar_msg_dialog "Error al intentar eliminar la rich rule.\nVerifique que la regla exista exactamente como fue agregada."
  return 1
  fi
  return 0
fi


# validación de la IP
if ! validar_ip_simple $IP; then
    mostrar_msg_dialog "La ip $IP no es válida"
    return 1
fi

# Pedir el servicio
local servicio=$(mostrar_input_dialog "Ingrese el servicio asociado a la regla" "ssh")
if ! verificar_servicio $servicio; then
    mostrar_msg_dialog "El servicio $servicio no es válido o no está disponible"
    return 1
fi

local metodo=$(dialog --stdout --clear --erase-on-exit --no-shadow --no-cancel --menu "Ingrese el metodo asociado a la regla" 15 53 6 \
1 "accept" \
2 "reject")

case $metodo in
1)
# Construcción de la regla exacta (debe coincidir con la agregada)
local regla="rule priority=100 family=ipv4 source address=\"$IP\" service name=\"$servicio\" accept"

# Eliminar regla de aceptación
if sudo firewall-cmd --permanent --remove-rich-rule="$regla"; then
mostrar_msg-title_dialog "Regla \n $regla \n eliminada con éxito" "OPERACIÓN EXITOSA"
else
mostrar_msg-title_dialog "Error al eliminar la regla.\n Código de error:$?" "ERROR"
fi
sudo firewall-cmd --reload
;;
2)
# Construcción de la regla exacta
local regla="rule priority=10000 family=\"ipv4\" source address=\"$IP\" service name=\"$servicio\" reject"

if sudo firewall-cmd --permanent --remove-rich-rule="$regla"; then
mostrar_msg-title_dialog "Regla \n $regla \n eliminada con éxito" "OPERACIÓN EXITOSA"
else
mostrar_msg-title_dialog "Error al eliminar la regla.\n Código de error:$?" "ERROR"
fi

sudo firewall-cmd --reload
;;
esac
}

denegarservicioIP() {
mostrar_msg-title_dialog "La siguiente operación removerá una IP de un servicio, es decír que tal IP no estará disponible para conectarse mediante ese servicio/puerto"
local IP=$(mostrar_input_dialog "Ingrese una IP" "")

# Verificación de la IP
 if ! validar_ip_simple $IP; then
    mostrar_msg_dialog "La ip $IP no es una ip valida"
    return 1
 fi
# Ingresar servicio para deshabilitar la ip dada
 local servicio=$(mostrar_input_dialog "Ingrese el servicio a deshabilitar por ip" "ssh")

# Verificar servicio
if ! verificar_servicio $servicio; then
 mostrar_msg_dialog "el servicio $servicio no es un servicio disponible"
 return 1
fi

# Encendemos el servicio para que sea posible conectarse
sudo firewall-cmd --permanent --add-service="$servicio"

# Armar regla
local regla="rule priority=10000 family=\"ipv4\" source address=\"$IP\" service name=\"$servicio\" reject"

if sudo firewall-cmd --permanent --add-rich-rule="$regla"; then
  sudo firewall-cmd --reload
  mostrar_msg_dialog "Regla \n $regla \n agregada con éxito"
else
  mostrar_msg-title_dialog "Error inesperado al agregar la regla, codigo de error: $?" "ERROR"
fi
}


menuRichRules() {
while true; do
local ingreso=$(dialog --erase-on-exit --no-cancel --title "MENU DE RICH RULES" --stdout --menu \
"Todas las rich rules serán aplicadas a la zona por default" 15 53 6 \
 1 "Consultar todas las RichRules" \
 2 "Consultar reglas por IP" \
 3 "Permitir servicio por una sola IP" \
 4 "Denegar servicio a una IP" \
 5 "Eliminar una rich rule" \
 6 "Opciónes zona drop" \
 X "Salir"
)
case $ingreso in
1)consultarReglas;;
2)consultarIPReglas;;
3)PermitirIPreglas;;
4)denegarservicioIP;;
6)
  while true; do
  local ing=$(dialog --erase-on-exit --no-cancel --stdout --no-shadow --title "SUBMENU ZONA DROP" --menu "Ingrese una opción" 15 30 6 \
   1 "Mover IP a zona drop" \
   2 "Eliminar IP de zona drop" \
   3 "Consultar IPs en zona drop" \
   X "Salir")
  case $ing in
  1)
local ingresoIP=$(mostrar_input_dialog "Ingrese una IP a añadir a la zona drop")
  if validar_ip_simple $ingresoIP; then
    sudo firewall-cmd --permanent --zone=drop --add-source="$ingresoIP" && mostrar_msg_dialog "IP $ingresoIP agregada con exito a la zona drop"
    sudo firewall-cmd --reload
  else
    mostrar_msg_dialog "La dirección $ingresoIP no es una ip"
  fi
  ;;
  2)
  # Obtiene todas las direcciónes IPs dentro de la zona drop
  local operacion=$(sudo firewall-cmd --permanent --zone=drop --list-sources | tr ' ' '\n')
  # Si la variable operacion está vacía ...
  if [ -z "$operacion" ]; then
    mostrar_msg_dialog "No hay IPs en la zona drop"
    break
  fi
  # Ingresar una IP a eliminar
  local ingresoIP=$(dialog --keep-window --no-cancel --title "IPs EN LA ZONA DROP" --msgbox "$operacion" 9 30 --and-widget \
  --title "ELIMINAR IP" --stdout --inputbox "Ingrese la ip a eliminar" 9 30 "")
  # si canceló la operación ...
  [ $? -ne 0 ] && break
  # Busca si la IP es correcta
  local op=$(sudo firewall-cmd --permanent --zone=drop --list-sources | tr ' ' '\n' | grep -qw "$ingresoIP")
  if validar_ip_simple $ingresoIP; then
    if $op; then
      # SI la ip existe la elimina
      sudo firewall-cmd --permanent --zone=drop --remove-source="$ingresoIP" && mostrar_msg_dialog "Se eliminó la ip $ingresoIP con éxito"
      sudo firewall-cmd --reload
    else
      mostrar_msg_timeout "La ip $ingresoIP no está en la zona drop" "ERROR"
    fi
  else
  mostrar_msg_dialog "La dirección $ingresoIP no es una ip"
  fi
;;
  3)
# lista todas las direcciónes IPs dentro de la zona drop
local operacion=$(sudo firewall-cmd --permanent --zone=drop --list-sources | tr ' ' '\n')
if [ -z "$operacion" ]; then
operacion="sin IPs en la zona drop"
fi
mostrar_msg-title_dialog "$operacion" "IPs EN LA ZONA DROP"
;;
  X)break;;
  esac
  done
;;
5)
eliminarRegla
;;
X)
break
;;
esac
done
}
menuRichRules
