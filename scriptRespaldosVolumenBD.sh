#!/bin/bash
# crea una carpeta si no existe mkdir -p
mkdir -p /opt/respaldos/volumenBD
tar -cvf /opt/respaldos/volumenBD/respaldoVolumenBD$(date -I).tar.gz /var/lib/docker/volumes/proyecto_db-data/
echo "-respaldo-volumen-bd-$(date -I)" >> /var/log/proyectoAura.log
