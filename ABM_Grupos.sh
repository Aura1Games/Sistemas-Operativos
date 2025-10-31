#!/bin/bash

source config.sh # se importa las funciónes creadas en el script ABM_Usuarios
#	Funciones disponibles desde el otro script:
# mostrar_información : Muestra todos los detalles del usuario dado
# mostrar_usuarios : Muestra los usuarios no creados por el sistema UID >= 1000
# validar_usuaro : Evalúa si el usuario dado existe en el sistema
# verificar_sudoer : evalúa quien está ejecutando el script

listar_grupos() {
# en /etc/group la sintaxis es: nombre_grupo:x:GID:usuarios
# los $numero identifican los campos
resultado=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1, $3}' /etc/group) # -F Define el delimitador de awk y {} es la salida del comando
echo "$resultado"
}
evaluar_grupo_principal() {
# las variables declaradas con -> local serán variables locales de la función
local grupo="$1"
# obtiene el id del grupo dado con getent para consultar y cut para obtener el valor deseado
local grupo_gid=$(getent group "$grupo" | cut -d: -f3)
# -F indica el delimitador; -v crea una variable intera con el valor de la varibale ya creada anteriormente grupo_gid
# recorre /etc/passwd y con esa salida obtiene con awk los usuarios que tienen como grupo principal el GID extraido anteriormente
local usuarios=$(getent passwd | awk -F: -v gid="$grupo_gid" ' $4 == gid {print $1}')

# Evalúa si la variable está vacía
if [ -z "$usuarios" ]; then
# el grupo puede eliminarse (no es el grupo principal de ningun usuario)
return 0
else
# el grupo está siendo usado por uno o muchos usuarios
echo "El grupo $grupo es el principal de: "
# reemplaza (s) el principio de la línea (^) con (  - ) para darle un formato mas amigable a la lista (si mas de un usuario usa el grupo como principal)
echo "$usuarios" | sed 's/^/  - /'
echo -e "- No se puede eliminar el grupo principal de ningun usuario, \n - Si deseas eliminar el grupo requiere ser modificado en el ABM_Usuarios de el/los usuario/s anteriormente dictado/s"
read -p "- Presione ENTER para continuar "
return 1
fi
}

Menu_principal_GRUPOS(){
clear
echo "========================"
echo "       ABM GRUPOS       "
echo "========================"
echo "1. Crear un grupo"
echo "2. Borrar un grupo"
echo "3. Modificar un grupo"
echo "4. Información de grupo"
echo "0. Salir"
echo "========================"
}
# devuelve verdadero si el grupo existe
validar_grupo() {
# local refiere a que es una variable solo de la función, no tiene uso fuera de la función
local grupo="$1"
# busca $grupo en /etc/group y silencia la salida del comando con >/dev/null
if getent group "$grupo" >/dev/null; then
return 0
else
return 1
fi
}
verificar_sudoer
# Menu principal
while true; do
Menu_principal_GRUPOS
read -p "- Ingrese una opción: " op
if [[ -n "$op" ]]; then # -n devuelve verdadereo si la variable contiene algo
case $op in
1)
clear
echo "==============="
echo "  CREAR GRUPO  "
echo "==============="
read -p "Ingrese el nombre del grupo: " nombre_grupo
if [ -z "$nombre_grupo" ]; then # -z devuelve verdadero si la variable está vacía
echo "¡El grupo debe de tener un nombre!"
elif ! validar_grupo "$nombre_grupo"; then
sudo groupadd "$nombre_grupo"
read -p "- Grupo [ $nombre_grupo ] creado con exito"
else
read -p "- El grupo $nombre_grupo ya existe"
fi
;;
2)
clear
echo "================"
echo "  BORRAR GRUPO  "
echo "================"
# función para listar los grupos no creados por el sistema
listar_grupos
read -p "- Ingrese el nombre del grupo: " eliminar_grupo
if validar_grupo "$eliminar_grupo"; then
read -p "¿Deseas eliminar permanentemente el grupo [ $eliminar_grupo ] ? [ENTER para continuar / no para cancelar]" op
if [ -n "$op" ]; then # si la variable no está vacía 
 read -p "- Eliminación del grupo [ $eliminar_grupo ] cancelada"
else
# if para evaluar si el grupo no es un grupo principal de un usuario

if evaluar_grupo_principal "$eliminar_grupo"; then
sudo groupdel "$eliminar_grupo"
read -p "Eliminación del grupo $eliminar_grupo exitosa"
fi
fi

else
read -p "- El grupo [ $eliminar_grupo ] no existe [Presiona ENTER para regresar al menu]"
fi
;;
3)
clear
echo "- Si deseas modificar el grupo principal de un usuario ó los grupos secundarios se encuentra en modificación de usuarios "
read -p "[Presione ENTER para ir a ABM_Usuarios / no para declinar]" opp
if [ -z "$opp" ]; then
echo "Redirigiendo a ABM_Usuarios..."
sleep 2
source ABM_Usuarios.sh
read -p ""
else
read -p "- Redireccionamiento cancelado"
fi
;;
4)
clear
echo "================="
echo "  LISTAR GRUPOS  "
echo "================="
echo "1. Simple (solo nombres + id grupo)"
echo "2. Completo (toda la información)"
echo "================="
read -p "Ingrese una opción: " pp
case $pp in
1)
listar_grupos
read -p ""
;;
2)
resultado=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $0}' /etc/group) # -F Define el delimitador de awk y {} es la salida del comando
read -p "$resultado"
;;
*)
read -p "[ERROR] Comando no valido..."
;;
esac

;;
0)
echo "Saliendo ..."
sleep 1
break
;;
*)
read -p "ERROR: Comando no valido"
;;
esac
fi
done
