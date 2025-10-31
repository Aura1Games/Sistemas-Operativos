#!/bin/bash

ingobox_dialog() {
# ingobox_dialog "Mensaje" "Titulo"
dialog --title "$2" --infobox "$1" 3 45
sleep 1
}
msgbox_dialog() {
# msgbox_dialog "Mensaje" "Titulo"
dialog --no-cancel --title "$2" --msgbox "$1" 7 30
}

msgbox_dialog_xxl() {
# msgbox_dialog "Mensaje" "Titulo"
dialog --no-cancel --title "$2" --msgbox "$1" 20 70
}

servidor_py() {
while true; do
local ingreso=$(dialog --stdout --no-cancel --clear --menu "Ingrese una opción:" 15 50 6 \
1 "Levantar servidor python en segundo plano" \
2 "Mostrar los servicios que se ejecutan en segundo plano" \
3 "Ejecutar en primer plano un servicio en segundo plano" \
4 "Mostrar los puertos y servicios en uso" \
X "Salir")

case $ingreso in
1)msgbox_dialog "Levantando servidor python en segundo plano..." "SERVIDOR PYTHON";;
2)msgbox_dialog "aun no programado..." "SERVICIOS EN SEGUNDO PLANO";;
3)msgbox_dialog "aun no programado" "EJECUTAR EN PRIMER PLANO" ;;
4)msgbox_dialog_xxl "$(ss -tuln)" "PUERTOS Y SERVICIOS EN USO";;
X)
break
;;

esac
done
}




while true; do
	clear
	opcion=$(dialog --no-cancel --erase-on-exit --stdout --clear --title "Menú principal" --menu \
	"Ingrese una opción" 15 40 6 \
	1 "ABM de Usuarios" \
	2 "ABM de Grupos" \
	3 "Administración de Firewall " \
	4 "Opciónes de respaldos" \
 	5 "Servidor python" \
	X "Salir")
	case $opcion in
	1)
	ingobox_dialog "Redirigiendo al ABM de Usuarios..." "- REDIRECCIÓN -"
	sudo ./ABM_Usuarios.sh
	;;
	2)
	ingobox_dialog "Redirigiendo al ABM de Grupos..." "- REDIRECCIÓN -"
	sudo ./ABM_Grupos.sh
	;;
	3)
	ingobox_dialog "Redirigiendo a firewall..." "- REDIRECCIÓN -"
	sudo ./firewall.sh
	;;
	4)
	ingobox_dialog "Redirigiendo a respaldos..." "- REDIRECCIÓN -"
	msgbox_dialog "La función aún no se programó" "- ALERTA -"
	;;
	5)
	servidor_py
	;;
	X)
	clear
	exit 0 # salir del bucle while
	;;
	esac
	done
