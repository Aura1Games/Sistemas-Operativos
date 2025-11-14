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

opciones_respaldos() {
local opcion=$(dialog --no-cancel --erase-on-exit --stdout --clear --title "Menú respaldos" --menu \
        "Ingrese una opción" 17 55 6 \
        1 "Crear un respaldo completo" \
        2 "Crear un respaldo de volumen del contenedor BD" \
        X "Salir")

case $opcion in
1)sudo bash /opt/scripts/scriptRespaldoFUll.sh && msgbox_dialog "Respaldo creado con éxito" "Creación de respaldo completo"
# Log
echo "-respaldo-carpetaPersonal-full hecho por el usuario-$(date -I)" >> /var/log/proyectoAura.log
;;
2)sudo bash /opt/scripts/scriptRespaldoVolumenes.sh && msgbox_dialog "Respaldo creado con éxito" "Creación de respaldo de volumen"
echo "-respaldo-volumen-bd hecho por el usuario-$(date -I)" >> /var/log/proyectoAura.log
;;
X)break;;
esac
}

mostrar_input_dialog() {
# mostrar_input_dialog "Mensaje" "TITULO" "placeholder"
local mensaje="$1"
local titulo="$2"
local placeholder="$3"
dialog --erase-on-exit --stdout --title "$titulo" --inputbox "$mensaje" 8 45 "$placeholder"
local estado=$?
if ! [ $estado -eq 0 ]; then
return 1
fi
}

consultar_logs(){

        local opcion=$(dialog --no-cancel --erase-on-exit --stdout --clear --title "Menú logs" --menu \
        "Ingrese una opción" 15 55 6 \
        1 "Ver todos los logs" \
        2 "Filtrar por año-mes-día" \
        X "Salir")

        case $opcion in
        1)
        msgbox_dialog_xxl "$(cat /var/log/proyectoAura.log)" "- LOGS DEL SISTEMA CRUD -"
        ;;
        2)
                local year=$(mostrar_input_dialog "Ingrese el año ej:2025" "- CONSULTAR LOGS -" "2025")
                local mes=$(mostrar_input_dialog "Ingrese el mes ej: noviembre = 11" "- CONSULTAR LOGS -" "11")
                local dia=$(mostrar_input_dialog "Ingrese el dia ej: 08" "- CONSULTAR LOGS -" "08")
                        if [[ -z "$year" || -z "$mes" || -z "$dia" ]]; then
                        msgbox_dialog "Los parametros no deben de estár vacios" "ALERTA"
                        return 1;
                fi
                msgbox_dialog_xxl "$(awk -F- -v Y="$year" -v M="$mes" -v D="$dia" \
                '$5 == Y && $6 == M && $7 == D {print $0}' /var/log/proyectoAura.log)" \
                "- LOGS DEL SISTEMA CRUD -"
                # -v especifica la creación de variables dentro de awk, variables creadas: Y, M y D.
        ;;
        X)
        return 0
        ;;
        esac

}


administrar_docker(){
while true; do
local opcion=$(dialog --no-cancel --erase-on-exit --stdout --clear --title "Menú docker" --menu \
        "Ingrese una opción" 15 55 6 \
        1 "Consultar contenedores" \
        2 "Consultar volumenes" \
        3 "Levantar contenedor web" \
        4 "Apagar el contenedor web-bd" \
        5 "Levantar aplicación web-bd" \
        6 "Apagar el contenedor web" \
        X "Salir")
case $opcion in
1)
local auxiliarContenedores=$(docker ps -a)
msgbox_dialog_xxl "$auxiliarContenedores"
;;
2)
local auxiliarVolumen=$(docker volume ls)
msgbox_dialog_xxl "$auxiliarVolumen"
;;
3)
# xdg-open sirve para abir URLs en el navegador.
docker run -d --name web -p 6464:80 proyecto-web:latest && \
msgbox_dialog "Contenedor expuesto correctamente \n Acceso: 192.168.56.101:6464/public/" "| CONTENEDOR EXPUESTO |"
# Log
echo "-docker-contenedorWeb-levantado correctamente-$(date -I)" >> /var/log/proyectoAura.log
;;
4)
cd /home/proyecto && docker compose down && msgbox_dialog "Aplicación web apagada con éxito" "| APP WEB |"
;;
5)
cd /home/proyecto && docker compose up -d && msgbox_dialog "Se levantó correctamente la aplicación web" "| APP WEB |"
echo "-docker-aplicacionWebBd-levantada correctamente-$(date -I)" >> /var/log/proyectoAura.log
;;
6)
dialog --erase-on-exit --clear --stdout --title "Titulo" \
--yesno "Recuerda que para apagar un contenedor primero debes de encenderlo, ¿deseas continuar de todas formas?" 9 30

if ! [ $? -eq 0 ]; then
return 1
fi
docker stop web && docker container prune -f && \
msgbox_dialog "Apagado y removido correctamente"
echo "-docker-aplicacionWebBd-apagada correctamente-$(date -I)" >> /var/log/proyectoAura.log
;;
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
        4 "Opción de respaldos" \
        5 "Administrar Docker" \
        6 "Consultar Logs" \
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
        opciones_respaldos
        ;;
        5)
        ingobox_dialog "Regirigiendo a administrador de Docker" "- REDIRECCIÓN -"
        administrar_docker
        ;;
        6)
        consultar_logs
        ;;
        X)
        clear
        exit 0 # salir del bucle while
        ;;
        esac
        done
