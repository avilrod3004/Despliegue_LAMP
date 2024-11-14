#!/bin/bash

# Cargar variables de entorno desde .env
if [ -f .env ]; then
    source .env
else
    echo "ERROR: No se ha encontrado el archivo .env" >&2
    exit 1
fi

# Validar que la variable está cargada
if [[ -z "$PHPMYADMIN_APP_PASSWORD" ]]; then
    echo "ERROR: La variable PHPMYADMIN_APP_PASSWORD no están definidas en .env" >&2
    exit 1
fi

# Verificar permisos de superusuario
if ! sudo -v > /dev/null 2>&1; then
    echo "ERROR: Este script requiere permisos de superusuario." >&2
    exit 1
fi

# Función para manejar errores
mensaje_error() {
    if [ $? -ne 0 ]; then
        echo "ERROR: $1" >&2
        echo "Comando donde ha fallado: ${BASH_COMMAND}" >&2
        exit 1 # En caso de error termina la ejecución del script
    fi
}

# Preseleccionar las opciones
# Seleccionar el servidor web -> apache2
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
mensaje_error "Falló la configuración del servidor web para phpMyAdmin."

# Confirmar para usar dbconfig-common para configurar la base de datos
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
mensaje_error "Falló la preconfiguración de dbconfig-common para phpMyAdmin."

# Seleccionar la contraseña
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections
mensaje_error "Falló la confirmación de la contraseña de phpMyAdmin."

# Iniciar instalación de phpMyAdmin
sudo apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y
mensaje_error "La instalación de phpMyAdmin o sus dependencias ha fallado."

# Reiniciar Apache para aplicar los cambios
sudo systemctl restart apache2
mensaje_error "Falló al reiniciar Apache después de instalar phpMyAdmin."

echo "¡phpMyAdmin instalado y configurado!"