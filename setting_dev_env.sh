#!/bin/bash
valid_password=false
while [ "$valid_password" = false ]; do
    read -s -p "Introduzca el password que usara el usuario root en MySQL: " password_a
    read -s -p "Confirme el password del usuario root en MySQL: " password_b
    if [ "$password_a" == "$password_b" ]; then
        echo "Se define la contraseña de usuario root en MySQL: ${password_a}"
        valid_password=true
    fi
done

read -p "Introduzca el nombre del entorno virtual de python: " python_vent
PY_VENT_DIR="$(pwd)/py_dev"

echo "Actualiza repositorios"
sudo apt -y update
sudo apt -y upgrade
echo "--------------------------------------------------------------------------------- \n"

echo "Instala Apache"
sudo apt -y install apache2 unzip
echo "--------------------------------------------------------------------------------- \n"

echo "Actualiza el puerto de escucha"
sudo cp /etc/apache2/ports.conf /etc/apache2/ports.conf.bak
sudo sed -i 's/Listen 80/Listen 8081/' "/etc/apache2/ports.conf"
echo "--------------------------------------------------------------------------------- \n"

echo "Reinicia apache para cargar los cambios"
sudo service apache2 restart
echo "--------------------------------------------------------------------------------- \n"

echo "Actualiza la carpeta de trabajo de apache"
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak
#sudo sed -i 's///' /etc/apache2/sites-available/000-default.conf
sudo sed -i 's|DocumentRoot /var/www/hml|DocumentRoot /var/www|' /etc/apache2/sites-available/000-default.conf
echo "--------------------------------------------------------------------------------- \n"

echo "Asigna permisos al usuario actual a la carpeta de trabajo de apache"
sudo chown -R $USER:$USER /var/www
sudo chmod -R 755 /var/www
echo "--------------------------------------------------------------------------------- \n"

echo "Actualiza configuraciones de apache"
sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
sudo sed -i 's/User root/'"User $USER"'/' /etc/apache2/apache2.conf
sudo sed -i 's/Group root/'"Group $USER"'/' /etc/apache2/apache2.conf
echo "--------------------------------------------------------------------------------- \n"

echo "Instala PHP"
sudo apt install -y php libapache2-mod-php php-mysql php-xml php-cli php-curl php-zip php-json php-mbstring
PHP_VER=$(php -v | grep -Po "[0-9]\.[0-9]" | head -n 1)
echo "--------------------------------------------------------------------------------- \n"

echo "Instala xdebug"
sudo apt-get install -y php-xdebug
sudo cp /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini.bak
sudo bash -c "echo 'xdebug.remote_enable=1' >> /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini"
sudo bash -c "echo 'xdebug.remote_port=9000' >> /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini"
sudo bash -c "echo 'xdebug.remote_log="/tmp/xdebug.log"' >> /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini"
echo "--------------------------------------------------------------------------------- \n"

echo "Configura xdebug"
WSLIP=$(grep nameserver /etc/resolv.conf | cut -d ' ' -f2)
sudo bash -c "echo "xdebug.remote_host=$WSLIP" >> /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini"
sudo cp ~/.bashrc ~/bashrc.bak
sudo chmod -R og+w /etc/php/$PHP_VER/apache2/conf.d/ #current user need to be able to write to the file
sudo echo 'sed -ri "s|xdebug.remote_host=[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}|xdebug.remote_host=$WSLIP|" /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini' >> ~/.bashrc
echo "--------------------------------------------------------------------------------- \n"

echo "Instala MySQL"
sudo apt -y install mysql-server
sudo chown mysql:mysql -R /var/run/mysqld/
sudo chmod 755 -R /var/run/mysqld/
echo "--------------------------------------------------------------------------------- \n"

echo "Inicia MySQL"
sudo usermod -d /var/lib/mysql/ mysql
sudo service mysql start
echo "--------------------------------------------------------------------------------- \n"

echo "Configura el usuario root"
echo -e "Copia la siguiente linea y pegala en el promt de MySQL para ejecutarla:"
echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$password_a';"
sudo mysql -Bse "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$password_a';"
#sudo mysql_secure_installation
echo "--------------------------------------------------------------------------------- \n"

echo "Instala y configura phpmyadmin"
#sudo apt install -y phpmyadmin
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-english.zip
unzip phpMyAdmin-5.2.1-english.zip
sudo rm phpMyAdmin-5.2.1-english.zip
sudo mv phpMyAdmin-5.2.1-english /usr/share/phpmyadmin
sudo mkdir /usr/share/phpmyadmin/tmp 
sudo chown -R www-data:www-data /usr/share/phpmyadmin
sudo chmod 777 /usr/share/phpmyadmin/tmp
sudo chmod 777 /etc/apache2/conf-available/
sudo cat > /etc/apache2/conf-available/phpmyadmin.conf<<FILE_TEXT
Alias /phpmyadmin /usr/share/phpmyadmin
Alias /phpMyAdmin /usr/share/phpmyadmin
 
<Directory /usr/share/phpmyadmin/>
   AddDefaultCharset UTF-8
   <IfModule mod_authz_core.c>
      <RequireAny>
      Require all granted
     </RequireAny>
   </IfModule>
</Directory>
 
<Directory /usr/share/phpmyadmin/setup/>
   <IfModule mod_authz_core.c>
     <RequireAny>
       Require all granted
     </RequireAny>
   </IfModule>
</Directory>
FILE_TEXT
sudo a2enconf phpmyadmin
echo "--------------------------------------------------------------------------------- \n"

echo "Crea archivo de control de entorno"
sudo cat > dev_env_opt.sh<<FILE_TEXT
#!/bin/bash
OPTION="\${1^^}"
if [ "\$OPTION" == "START" ]; then
    sudo service apache2 start
    sudo service mysql start
elif [ "\$OPTION" == "STOP" ]; then
    sudo service apache2 stop
    sudo service mysql stop
elif [ "\$OPTION" == "RESTART" ]; then
    sudo service apache2 restart
    sudo service mysql restart
elif [ "\$OPTION" == "STATUS" ]; then
    sudo service apache2 status
    sudo service mysql status
else
    echo "The options are start, stop and restart";
fi
FILE_TEXT
echo "--------------------------------------------------------------------------------- \n"

echo "Crea archivos de mantenimiento de Ubuntu"
sudo cat > update_ubuntu.sh<<FILE_TEXT
#!/bin/bash
echo "Comienza el update"
sudo apt -y update
echo "--------------------------------------------------------------------------------- \n"
echo "Comienza el upgrade"
sudo apt -y upgrade
echo "--------------------------------------------------------------------------------- \n"
echo "Comienza el autoremove"
sudo apt -y autoremove
echo "--------------------------------------------------------------------------------- \n"
echo "Comienza el autoclean"
sudo apt -y autoclean
echo "--------------------------------------------------------------------------------- \n"
FILE_TEXT

sudo cat > uninstall_packages.sh<<FILE_TEXT
#!/bin/bash
APP="\${1,,}"

echo \$APP
echo "Comienza el remove"
sudo apt -y remove \$APP
echo "--------------------------------------------------------------------------------- \n"
echo "Comienza el purge"
sudo apt -y purge \$APP
echo "--------------------------------------------------------------------------------- \n"
echo "Comienza el clean"
sudo apt -y clean \$APP
echo "--------------------------------------------------------------------------------- \n"
FILE_TEXT
echo "--------------------------------------------------------------------------------- \n"

echo "Actualiza permisos, grupos y propietarios de los archivos recien creados"
sudo chmod 777 dev_env_opt.sh update_ubuntu.sh uninstall_packages.sh
sudo chown $USER: dev_env_opt.sh update_ubuntu.sh uninstall_packages.sh
echo "--------------------------------------------------------------------------------- \n"

echo "Instala el componente venv de Python y configura un el entorno virtual"
sudo apt -y install python3.10-venv
sudo python3 -m venv $PY_VENT_DIR