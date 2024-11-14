# Despliegue_LAMP

Actualizar repositorios y paquetes:
```bash
sudo apt update
sudo apt upgrade -y
```

# Instalación LAMP

## Apache
Instalar Apache:
```bash
sudo apt install apache2 -y
```

Iniciar Apache:
```bash
sudo systemctl enable apache2
sudo systemctl start apache2
```

Comprobar que está en ejecución:
```bash
sudo systemctl status apache2
```

## MySQL Server
Instalación:
```bash
sudo apt install mysql-server -y
```

Iniciar servicio:
```bash
sudo systemctl start mysql
```
Comprobar que está en ejecución:
```bash
sudo systemctl status mysql
```

Acceder a MySQL como root:
```bash
sudo mysql -u root -p
```

### Crear la base de datos
```sql
CREATE DATABASE db_name DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
```

### Crear usuario para acceder a la BD
```sql
CREATE USER 'db_user'@'localhost' IDENTIFIED BY 'contraseña_segura';
```

### Conceder permisos al usuario
```sql
GRANT ALL PRIVILEGES ON db_name.* TO 'db_user'@'localhost';
```

### Aplicar los cambios
```sql
FLUSH PRIVILEGES;
```

> Salir de MySQL: `EXIT;`

## PHP

Instalación:
```bash
sudo apt install php libapache2-mod-php php-mysql -y
```

Reiniciar Apache para que se apliquen los cambios:
```bash
sudo systemctl restart apache2
```

# Instalación de phpMyAdmin
Instalación:
```bash
sudo apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y
```

Durante el proceso de la instalación aparece una ventana para elegir que servidor web configurar para ejecutar phpMyAdmin. En este caso elegir el servidor web apache2.

Confirmar que queremos usar `dbconfig-common` para configurar la base de datos.

Por último, pedirá una contraseá para phpMyAdmin.

Podemos acceder a la interfaz web de phpMyAdmin desde la URL `http://ip/phpmyadmin`. La IP será la dirección IP de la máquina.