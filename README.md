# Sistemas-Operativos
Respaldo de scripts de sistemas operativos del proyecto Sistema Gestor de Partidas de Draftosaurus

### Objetivos general del los scripts
Los scripts en el repositorio actual forman parte del contenido del serviodor que va a levantar la pagina web del proyecto curricular [S.I.G.P.D.](https://github.com/Aura1Games/Proyecto-Poke-Saurus), en el mismo se encuentra la manipulación de usuarios, grupos, firewallD, Docker y respaldos. 

### Distribución de los scripts

- Menu_abm.sh ( Punto de entrada de los scripts )
- |- ABM_Usuarios.sh ( Script de operaciónes CRUD de usuarios + agregar grupos a los usuarios)
- |- ABM_Grupos.sh ( Script  de opreaciónes CRUD de grupos - sin agregar grupos a los usuarios )
- |- firewall.sh ( Script CRUD de operaciónes del firewallD del sistema)
- |- scriptRespaldos.sh (Script de creación de resplados de la carpeta home del usuario proyecto)

#### Archivos de soporte 
- config.sh ( Script repositorio de funciónes usadas en ABM_Usuarios.sh y ABM_Grupos.sh )
- configFirewall.sh ( Script repositorio de funciónes usadas en firewall.sh )

