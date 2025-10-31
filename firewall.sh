#!/bin/bash
source configFirewall.sh
verificar_sudoer # Función traída de configFirewall.sh para verificar el poder de usuario

X_salir() {

dialog --erase-on-exit --yesno "¿Realmente quieres salir?" 6 30
   [ $1 -eq 0 ] && break
}

menuPrincipal() {
result=$(dialog --stdout --no-cancel --no-shadow --title "Menú Principal Firewall" --menu \
    "Seleccione una opción:" 15 40 5 \
    1 "Gestión de Servicios" \
    2 "Gestión de Puertos" \
    3 "Gestión de Zonas" \
    4 "Gestión de Rich Rules" \
    X "Salir del programa")

# $? refiere al estado del ultimo comando ejecutado
# if en línea, si se cumple lo primero entonces retorna X
echo $result
}

menuServicios() {
while true; do
local ingreso=$(dialog --no-cancel --stdout --title "MENU SERVICIOS" --menu "Ingrese una opción" 14 30 6 \
1 "Agregar servicio" \
2 "Remover servicio" \
3 "Consultar servicios" \
4 "Gestión SSH" \
X "Salir")


case $ingreso in
1)
local servicio=$(mostrar_input_dialog "Ingrese el servicio a agregar")
agregar_servicio "$servicio"
;;
2)
local servicio=$(mostrar_input_dialog "Ingrese el servicio a eliminar")
eliminar_servicio "$servicio"
;;
3)listar_servicios
;;
4)
gestion_ssh
;;
X)
break
;;
esac
done
}


menuZonasInterfaces(){
while true; do
local ingreso=$(dialog --no-cancel --stdout --title "MENU ZONAS E INTERFACES" --menu "Ingrese una opción" 21 45 6 \
1 "Ver datos de una zona" \
2 "Cambiar interfaces de zona" \
3 "Mostrar zonas activas" \
4 "Mostrar interfaces" \
5 "Mostrar zonas disponibles" \
6 "Cambiar zona default" \
7 "Ver zona default" \
X "Salir")

case $ingreso in
1)
local zona=$(dialog --no-cancel --stdout --no-shadow --inputbox "Ingrese la zona a consultar" 8 35 "FedoraServer")
listar_datos_zonas "$zona"
;;
2)
local interfaz=$(mostrar_input_dialog "Ingrese la interfaz a agregar" "enp0s...")
local zona=$(mostrar_input_dialog "Ingrese la zona a agregar la interfaz" "FedoraServer")
cambiar_interfaces_de_zona "$interfaz" "$zona"
;;
3)
mostrar_zonas_activas
;;
4)
listar_interfaces
;;
5)
zonas_disponibles
;;
6)
cambiar_zona_d
;;
7)
mostrar_msg_dialog $(firewall-cmd --get-default-zone)
;;
X)
break
;;
esac
done
}


menuPuertos() {
while true; do
local opcion=$(dialog --stdout --no-shadow --no-cancel  --title "MENU PUERTOS" --menu "LEASE EL MANUAL ANTES DE MANIPULAR PUERTO \n Ingrese una opción" 13 45 6 \
1 "Agregar Puertos" \
2 "Eliminar Puertos" \
3 "Consultar Puertos" \
4 "Manual de Puertos" \
X "Salir")
case $opcion in
1)
local puerto=$(mostrar_input_dialog "Ingrese un puerto/PROTOCOLO a agregar")
AgergarPuertos "$puerto"
;;
2)
mostrar_msg_dialog "$(listar_puertos)"
local puerto=$(mostrar_input_dialog "Ingrese un puerto/PROTOCOLO a remover")
EliminarPuertos "$puerto"
;;
3)
  local ingreso=$(dialog --stdout --no-shadow --no-cancel  --title "CONSULTAR PUERTOS" --menu "Ingrese una opción" 14 50 6 \
  1 "Consultar puertos disponibles" \
  2 "algoxd" \
  X "Salir")
  case $ingreso in
  1)mostrar_msg_dialog "$(listar_puertos)";;
  2)mostrar_msg_dialog "Futura implementación ";;
  X)break;;
  esac
;;
4)
local texto="Los puertos se pueden adjudicar de distinas maneras pero todas las formas siguen una sintaxys: <numeroPUERTO>/<PROTOCOLO> \n los protocolos siempre serán tcp o udp \n \n 1. Simple (un solo puerto): 22/tcp \n 2. Rango (desde un puerto A a un puerto B): 22-26/tcp"
dialog --no-cancel --title "MANUAL BASICO DE PUERTOS" --msgbox "$texto" 15 60
;;
X)
break
;;
esac
done
}




# Comienzo del script

while true; do
opcion=$(menuPrincipal)
case $opcion in
1)
menuServicios
;;
2)
menuPuertos
;;
3)
menuZonasInterfaces
;;
4)
menuRichRules
#dialog --erase-on-exit --no-cancel --msgbox "Listado de RichRules de la zona default $(firewall-cmd --get-default-zone): \n $(firewall-cmd --list-rich-rules)" 9 40
;;
X)
dialog --erase-on-exit --yesno "¿Realmente quieres salir?" 6 30
   [ $? -eq 0 ] && break

;;
esac
done
