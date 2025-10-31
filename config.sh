#!/bin/bash

# Archivo contenedor de funciónes de igual uso en ABM_Usuarios y ABM_Grupos


grupo_existe() {
    local grupo="$1"

    # Verificar si el grupo existe
    if grep -q "^$grupo:" /etc/group; then
        return 0
    else
        # Mostrar diálogo para crear el grupo
        op_grupo=$(dialog --title "| GRUPO EXISTE |" \
            --clear \
            --no-cancel \
            --infobox "El grupo $grupo no existe" 8 30 \
            --and-widget \
            --title "| GRUPO EXISTE |" \
            --stdout \
            --yesno "¿Deseas crear el grupo '$grupo'?" 10 40)

        local resultado=$?

        case $resultado in
            0) # Yes
                if sudo groupadd "$grupo"; then
                    dialog --title "| ÉXITO |" \
                        --msgbox "Grupo [$grupo] creado con éxito" 8 30
                    return 0
                else
                    dialog --title "| ERROR |" \
                        --msgbox "No se pudo crear el grupo [$grupo]" 8 30
                    return 1
                fi
                ;;
            1) # No
                return 1
                ;;
            *) # Error o cancelado
                return 1
                ;;
        esac
    fi
}

verificar_sudoer() {

    if [[ $EUID -eq 0 ]]; then
        return 0  # Es root o sudo
    else
        read -p "$(whoami) no tienes permisos de administrador. Presiona Enter para salir..."
        exit 1
    fi

}
mostrar_informacion() {
clear
echo "INFORMACIÓN DEL USUARIO"
echo "======================="
echo "Nombre: $usuario"
echo "ID: $(id -u $usuario)"
echo "Grupo prinicpal: $(id -gn $usuario)"
echo "Grupos secundarios: $(id -Gn $usuarios)"
echo "Carpeta personal: $(eval echo ~$usuario)" # el ~ significa la carpeta personal y eval primerp ejecuta ése comando antes del echo $usuario
echo "Shell: $(getent passwd $usuario | cut -d : -f 7)" # -d es el delimitador y -f 7 es el numero de campo a selecciónar, getent navega por la base de datos del sistema como las carpetas dentro de /etc/*
echo "======================"
 read -p "- Presione ENTER para continuar"
}
mostrar_usuarios() {
resultado=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd) # es como un grep con un if
echo "$resultado"
}
validar_usuario() { # evalúa si el argumento nuero 1 existe en la carpeta de usuarios del sistema
if grep -q "^$1:" /etc/passwd; then
return 0
else
return 1
fi
}
cambiar_grupo_principal() {
while true; do
    grupos_disponibles=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/group)

    dialog --title "| GRUPOS EN EL SISTEMA |" --no-cancel --msgbox "$grupos_disponibles" 15 35

    nuevo_grupo=$(dialog --no-shadow --title "| CAMBIAR GRUPO PRINCIPAL" --stdout --inputbox "Ingrese el nuevo grupo principal" 10 35 "")

    # Verificar si el usuario canceló o dejó vacío
    if [ $? -ne 0 ] || [ -z "$nuevo_grupo" ]; then
        dialog --clear --title "| CANCELADO |" --msgbox "Operación cancelada" 6 30
        break
    fi

    if grupo_existe "$nuevo_grupo"; then
        if sudo usermod -g "$nuevo_grupo" "$usuario"; then
            dialog --clear --title "| FELICIDADES |" --no-cancel \
                --msgbox "Grupo principal cambiado correctamente\nNuevo grupo principal: $nuevo_grupo" 10 35
        else
            dialog --clear --title "| ERROR |" --no-cancel \
                --msgbox "Error al cambiar el grupo principal" 8 30
        fi
    else
        dialog --clear --title "| ERROR |" --no-cancel --msgbox "El grupo $nuevo_grupo no existe" 8 30
    fi
    break
done
}
agregar_grupo_secundarios() {
        echo "AGREGAR A GRUPOS SECUNDARIOS"
        echo "----------------------------"
        # echo "Carpeta actual de $usuario : $(getent passwd $usuario | cut -d : -f 6)"

        read -p "Ingresa grupo a agregar (solo uno por vez): " grupo_agregar
if grupo_existe "$grupo_agregar"; then
        sudo usermod -aG "$grupo_agregar" "$usuario" #agrega grupo secundario sin modificar el anterior
        echo "El grupo $grupo_agregar se agregó correctamente."
else
        echo "ERROR: El grupo $grupo_agregar no existe"
fi

echo "Grupos actuales:"
groups "$usuario"
read -p "Presione ENTER para continuar..."
}
cambiar_carpeta_personal() {
        echo "CAMBIAR CARPETA PERSONAL"
        echo "------------------------"
        echo "Carpeta actual: $(eval echo ~$usuario)"
        read -p "Ingrese la nueva ruta completa: " nueva_carpeta
        if ! [ -d "$nueva_carpeta" ]; then # -d operador para evaluar si existe y si es una carpeta
        sudo usermod -d "$nueva_carpeta" -m "$usuario"
        echo "Carpeta personal cambiada correctamente"
        echo "Nueva carpeta: $nueva_carpeta"
        else
        echo "ERROR: La carpeta $nueva_carpeta no existe."
        fi

        read -p "Presione cualquier tecla para continuar"
}

