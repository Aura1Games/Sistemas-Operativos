#!/bin/bash

source config.sh
# funciónes disponibles
# mostrar_informacion  ->  muestra la información completa del usuario ordenada
# mostrar_usuarios  -> muestra los usuarios creado por los anfitriones
# validar_usuario  -> retorna verdadero si el usuario existe sino falso
# grupo_existe  -> devuelve verdadero si un grupo existe o intenta crear uno si el grupo no existe
# se usará funciónes que comienzen con EJ para señalizar que son funciónes de éste script que llaman a las funciónes del script config.sh

mostrar_msg_dialog() {
# mostrar_msg_dialog "Mensaje" "TITULO"
dialog --erase-on-exit --no-cancel --title "$2" --msgbox "$1" 9 40
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
mostrar_input-no-cancel() {
# mostrar_input-no-cancel "Mensaje" "TITULO" "placeholder"
local mensaje="$1"
local titulo="$2"
local placeholder="$3"
dialog --no-cancel --erase-on-exit --stdout --title "$titulo" --inputbox "$mensaje" 8 45 "$placeholder"
}
mostrar_infobox() {
# mostrar_infobox "Mensaje" "TITULO"
dialog --title "$2" --infobox "$1" 10 40
sleep 2
}

ingreso_usuario_dialog() {
	nombre_nuevo_usuario=$(mostrar_input_dialog "Ingrese el nombre del nuevo usuario" \
	"ALTA DE USUARIOS" "")
	[ $? -eq 1 ] && return 1

    if [ -z "$nombre_nuevo_usuario" ] || echo "$nombre_nuevo_usuario" | grep -q '\s'; then
        mostrar_msg_dialog "¡El nombre de usuario es obligatorio!" "| ERROR |"
        return 1   # Volvemos al menú principal
    elif validar_usuario "$nombre_nuevo_usuario"; then
       	mostrar_msg_dialog "¡El usuario [ $nombre_nuevo_usuario ] ya existe!" "| ERROR |"
        return 1   # Volvemos al menú principal
    fi
    grupo_wheel=$(mostrar_input_dialog "¿Agregar a [$nombre_nuevo_usuario] al grupo wheel? \\n [si para aceptar / vacío para declinar]" \
	"ALTA DE USUARIOS/GRUPO WHEEL" "")
	[ $? -eq 1 ] && return 1
    ruta_carpeta_de_trabajo=$(mostrar_input-no-cancel \
    "Ruta de carpeta de trabajo de $nombre_nuevo_usuario \\n [por defecto /home/$nombre_nuevo_usuario]" "ALTA DE USUARIOS/CARPETA DE TRABAJO" "")
	[ $? -eq 1 ] && return 1
    if [[ -z "$ruta_carpeta_de_trabajo" ]]; then
        # SI LA RUTA ESTÁ VACÍA SE LE ADJUDICA UNA
	ruta_carpeta_de_trabajo="/home/$nombre_nuevo_usuario"
    fi

    if ! grep -qw "^$ruta_carpeta_de_trabajo:" /etc/passwd; then
	# SI LA RUTA DE LA CARPETA DE TRABAJO NO EXISTE AÚN
      if [[ -z "$grupo_wheel" ]]; then
	# SI $grupo_wheel ESTÁ VACÍO
         sudo useradd -m -d "$ruta_carpeta_de_trabajo" -s /bin/bash "$nombre_nuevo_usuario"
      else
	# SI $grupo_wheel NO ESTÁ VACÍO
        sudo useradd -m -d "$ruta_carpeta_de_trabajo" -s /bin/bash -G wheel "$nombre_nuevo_usuario"
      fi
    else
       mostrar_msg_dialog "La ruta [$ruta_carpeta_de_trabajo] ya está en uso" "ERROR"
        return 1   # Regresa al menú principal
    fi

    #mostrar_msg_dialog "De no poder cambiar la contraseña ahora podrás hacerlo en modificación de usuarios" "- CAMBIO DE CONTRASEÑA -"
    #clear
    #sudo passwd "$nombre_nuevo_usuario"
    mostrar_infobox "Obteniendo datos del usuario..." "ALTA DE USUARIOS"

    idJugador=$(id "$nombre_nuevo_usuario")
    dialog --no-cancel --no-shadow --erase-on-exit --title "ALTA DE USUARIOS" --msgbox "Información del usuario creado \\n $idJugador" 9 40
    return 0  # Todo correcto → volvemos al menú principal
}




EJ_mostrar_informacion() {
  mostrar_informacion
}
EJ_mostrar_usuarios() {
  mostrar_usuarios
}
EJ_validar_usuario() {
  validar_usuario "$1"
}
EJ_grupo_existe() {
  grupo_existe "$1"
}

dialog_menu_principal(){
local ingreso
ingreso=$(dialog --stdout --no-cancel --erase-on-exit --title "ADMINISTRACIÓN DE USUARIOS" --menu "\n Seleccióne una opción" 16 70 8 \
1 "Cambiar grupo principal" \
2 "Agregar grupos secundarios" \
3 "Cambiar carpeta personal" \
4 "Ver información del usuario" \
5 "Cambiar contraseña del usuario" \
X "Salir")
echo $ingreso
}


# Función para verificar si un grupo existe

#Función para cambiar el grupo principal


# Funcion para agregar grupos secundarios

# Funcion para cambiar la carpeta personal


# Inicio del programa
verificar_sudoer

dialogMenuPrincipal() {
local ingreso=$(dialog --no-cancel --stdout --keep-window --clear --title "ABM DE USUARIOS" --menu \
"Menu principal" 15 40 6 \
1 "Agregar usuario" \
2 "Eliminar usuario" \
3 "Modificar usuario" \
4 "Listar usuarios creados" \
X "Volver al menú principal")
echo $ingreso
}
while true; do #Itera en el bucle hasta break
	opcion_usuario=$(dialogMenuPrincipal)

	case $opcion_usuario in
	1) # Agregar usuario
	 ingreso_usuario_dialog
	;;
	2) # Eliminar usuario
	 clear
         resultado=$(EJ_mostrar_usuarios)
	 mostrar_infobox "Obteniendo datos del sistema..." "| CARGANDO |"
	 mostrar_msg_dialog "${resultado[@]}" "| USUARIOS EN EL SISTEMA |"
	 usuario_eliminar=$(mostrar_input_dialog "Ingrese el usuario a eliminar" "| INGRESO DE DATOS |" "")
	 [ $? -eq 1 ] && break
	 if EJ_validar_usuario "$usuario_eliminar"; then # Verifica si el usuario existe en /etc/passwd
	   dialog --title "| ALERTA |" --yesno "¿Eliminar $usuario_eliminar permanentemente?" 6 50
	   if [[ $? -eq 0 ]]; then # $? almacena el estado de la ultima ejecución de comandos, 0 = si, 1 = no.
	     sudo userdel -r -f "$usuario_eliminar" && mostrar_msg_dialog "Usuario $usuario_eliminar eliminado correctamente" "| OPERACIÓN EXITOSA |"
	     # -f sirve para forzar la eliminación de un usuario si está logeado y -r elimina su directorio de trabajo
	     # break
	   else
	     mostrar_msg_dialog "Eliminación del usuario [$usuario_eliminar] cancelada" "| ALERTA |"
	     # break
	   fi

	 else
	   mostrar_msg_dialog "Usuario [$usuario_eliminar] no existe en el sistema" "| ERROR |"
	 fi
	;;
	3)
	 clear
	 resultado=$(EJ_mostrar_usuarios)
	 dialog --title "| CARGANDO |" --infobox "Obteniendo datos del sistema..." 5 27
	 sleep 1
	 usuario=$(dialog --no-cancel --title "| USUARIOS EN EL SISTEMA |" --msgbox "${resultado[@]}" 15 30 --and-widget \
	 --title "| INGRESO DE DATOS |" --no-shadow --stdout --no-cancel --inputbox "Ingrese el usuario a modificar" 8 30 "")
	 #verificar si el usuario existe
	 if ! EJ_validar_usuario "$usuario"; then
	   dialog --title "| ALERTA |" --no-cancel --msgbox "ERROR: El usuario $usuario no existe" 9 15
	 break
	 fi

	 while true; do
	 #mostrar_menu_principal
	  opcion=$(dialog_menu_principal)

	  case $opcion in
	  1) cambiar_grupo_principal ;;
	  2) agregar_grupo_secundarios ;;
	  3) cambiar_carpeta_personal ;;
	  4) EJ_mostrar_informacion ;;
	  X)
	   dialog --title "| REDIRECCIÓN |" --infobox "Regresando al ABM de usuario" 8 30
	   sleep 1
	  break
	;;
	5)
	 mostrar_infobox "Cambio de contraseña del usuario $usuario"
	 if EJ_validar_usuario "$usuario"; then
	   sudo passwd "$usuario" && mostrar_infobox "Usuario agregado con éxito" "Regresando al menú"
	 else
	   mostrar_infobox "Usuario no encontrado, cambio de contraseña no valida..." "ERROR"
	 fi
	;;
	 esac
	 done
	;;
	 "X")
	 clear
	 dialog --erase-on-exit --yesno "¿Realmente quieres salir?" 6 30
   	 [ $? -eq 0 ] && break
	;;
	4)
	clear
	opc=$(dialog --stdout --no-cancel --keep-window --clear --title "| CONSULTAR |" --menu \
	"Ingrese una opción" 15 40 6 \
	1 "Información completa de usuarios creados" \
	2 "Nombre usuarios creados" \
	X "Salir" \
	)
	  case $opc in
	  1)
	  resultado=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $0}' /etc/passwd) # el usuario nobody es uno creado por el sistema para servicios de minimos permisos
	  dialog --title "| CARGANDO |" --infobox "Cargando datos de usuarios en el sistema.." 5 30
	  sleep 1
	  dialog --no-cancel --title "| DATOS DEL SISTEMA |" --msgbox "INFORMACIÓN DE USUARIOS: \n \n ${resultado[@]}" 20 65 # arreglo[@] significa que seleccióna todos los elementos del arreglo
	  ;;
	  2)
	  resultado=$(EJ_mostrar_usuarios)
	  dialog --title "| CARGANDO |" --infobox "Cargando datos de usuarios en el sistema.." 5 30
	  sleep 1
	  dialog --no-cancel --title "| NOMBRES DE USUARIOS |" --msgbox "${resultado[@]}" 10 30
	  ;;
	  *)
	  dialog --title "| ALERTA |" --infobox "Ingreso Errone de Datos" 5 20
	  ;;
	  esac

	;;
	esac
	done
