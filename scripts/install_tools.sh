#!/bin/bash

# Verificar que se ha ejecutado primero el script para instalar y configurar LAMP
if [ ! -f /var/log/lamp_installed.flag ]; then
    echo "ERROR: El entorno LAMP no está instalado. Ejecute primero el script "install_lamp.sh"." >&2
    exit 1
fi

# Cargar variables de entorno desde .env
if [ -f .env ]; then
    source .env
else
    echo "ERROR: No se ha encontrado el archivo .env" >&2
    exit 1
fi

# Validar que la variable está cargada
if [[ -z "$PHPMYADMIN_APP_PASSWORD" || -z "$STATS_USERNAME" || -z "$STATS_PASSWORD" ]]; then
    echo "ERROR: Las variables PHPMYADMIN_APP_PASSWORD, STATS_USERNAME o STATS_PASSWORD no están definidas en .env" >&2
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
        exit 1 # En caso de error termina la ejecución del script
    fi
}


# Actualizar repositorios y paquetes
echo "Actualizando repositorios..."
sudo apt update
mensaje_error "Falló la actualización de repositorios."

echo "Actualizando paquetes..."
sudo apt upgrade -y
mensaje_error "Falló la actualización de paquetes."


# phpMyAdmin

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


# Adminer
# Crear directorio
mkdir -p /var/www/html/adminer
mensaje_error "No se ha podido crear la carpeta para guardar el archivo de Adminer"

# Descargar el archivo, indicando la ruta donde se va a guardar
wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php -P /var/www/html/adminer
mensaje_error "Ha ocurrido un fallo al descargar el archivo de Adminer"

# Para evitar errores si la descarga falla
if [ ! -f /var/www/html/adminer/adminer-*.php ]; then
    mensaje_error "El archivo de Adminer no existe tras la descarga."
fi

# Renombrar el archivo descargado de Adminer a un nombre sencillo
mv /var/www/html/adminer/adminer-*.php /var/www/html/adminer/adminer.php
mensaje_error "No se pudo renombrar el archivo de Adminer."


# GoAccess - Analizador de logs
# Instalación
sudo apt install goaccess -y
mensaje_error "No se ha podido instalar GoAccess"

# Crear directorio stats
mkdir -p /var/www/html/stats
mensaje_error "No se ha podido crear la carpeta stats"

# Crear archivo de contraseñas
sudo htpasswd -bc /etc/apache2/.htpasswd $STATS_USERNAME $STATS_PASSWORD
mensaje_error "Ha ocurrido un fallo al crear el archivo de contraseñas"

# Crear archivo .htaccess dentro del directorio que queremos proteger 
# y añadir contenido
sudo tee /var/www/html/stats/.htaccess > /dev/null <<EOL
AuthType Basic
AuthName "Acceso restringido"
AuthBasicProvider file
AuthUserFile "/etc/apache2/.htpasswd"
Require valid-user
EOL
mensaje_error "Ha ocurrido un error al crear el archivo .htaccess o al escribit en él"

# Editar archivo de configuración de Apache, añadir las líneas antes de la línea 20
sudo awk 'NR==20 {print "<Directory \"/var/www/html/stats\">\n AllowOverride All\n</Directory>\n"} {print}' /etc/apache2/sites-available/000-default.conf > temp && sudo mv temp /etc/apache2/sites-available/000-default.conf
mensaje_error "Ha ocurrido un fallo al editar el fichero de configuración de Apache"

# Reinciar Apache
sudo systemctl restart apache2
mensaje_error "Ha ocurrido un error al reinciar apache para aplicar los cambios"


# Mensajes finales
echo "¡phpMyAdmin instalado y configurado!"
echo "Para acceder a la interfaz web -> http://ip/phpmyadmin"

echo "¡Adminer instalado correctamente!"
echo "Para acceder a la interfaz web -> http://ip/adminer/adminer.php"

echo "¡GoAccess configurado!"