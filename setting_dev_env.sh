#!/bin/bash
DATE=$(date +%y%m%d%H%M)
DIR=$(pwd)
FILE_LOG=$DIR/setting_dev_env_$DATE.log
valid_password=false
while [ "$valid_password" = false ]; do
    read -s -p "Enter MySQL root password: " password_a 
    echo -e "\n"
    read -s -p "Confirm MySQL root password: " password_b
    echo -e "\n"
    if [ "$password_a" == "$password_b" ]; then
        echo -e "MySQL root password set: ${password_a}\n" >>$FILE_LOG
        valid_password=true
    fi
done

read -p "Enter python virtual enviroment name: " python_vent
echo -e "\n"
PY_VENT_DIR=$DIR/$python_vent

echo -e "<-Update repositories\n" >>$FILE_LOG
sudo apt -y update
sudo apt -y upgrade
echo -e "Repositories updated->\n" >>$FILE_LOG

echo -e "<-Install and set up apache\n" >>$FILE_LOG
sudo apt -y install apache2 unzip
sudo cp /etc/apache2/ports.conf /etc/apache2/ports.conf.bak
sudo sed -i 's/Listen 80/Listen 8081/' "/etc/apache2/ports.conf"
sudo service apache2 restart
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak
#sudo sed -i 's///' /etc/apache2/sites-available/000-default.conf
sudo sed -i 's|DocumentRoot /var/www/hml|DocumentRoot /var/www|' /etc/apache2/sites-available/000-default.conf
sudo chown -R $USER:$USER /var/www
sudo chmod -R 755 /var/www
sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
sudo sed -i 's/User root/'"User $USER"'/' /etc/apache2/apache2.conf
sudo sed -i 's/Group root/'"Group $USER"'/' /etc/apache2/apache2.conf
sudo cat > /var/www/html/phpinfo.php<<FILE_TEXT
<?php phpinfo(); ?>
FILE_TEXT

echo -e "Apache installed and configured->\n" >>$FILE_LOG

echo -e "<-Install PHP\n" >>$FILE_LOG
sudo apt install -y php libapache2-mod-php php-mysql php-xml php-cli php-curl php-zip php-json php-mbstring php-pear php-dev
PHP_VER=$(php -v | grep -Po "[0-9]\.[0-9]" | head -n 1)
echo -e "PHP installed->\n" >>$FILE_LOG

echo -e "<-Install and set up xdebug\n" >>$FILE_LOG
sudo apt-get install -y php-xdebug
sudo cp /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini.bak
sudo bash -c "echo 'xdebug.remote_enable=1' >> /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini"
sudo bash -c "echo 'xdebug.remote_port=9000' >> /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini"
sudo bash -c "echo 'xdebug.remote_log="/tmp/xdebug.log"' >> /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini"
WSLIP=$(grep nameserver /etc/resolv.conf | cut -d ' ' -f2)
sudo bash -c "echo "xdebug.remote_host=$WSLIP" >> /etc/php/$PHP_VER/apache2/conf.d/20-xdebug.ini"
sudo cp ~/.bashrc ~/bashrc.bak
sudo chmod -R og+w /etc/php/$PHP_VER/apache2/conf.d/ #current user need to be able to write to the file
sudo echo 'sed -ri "s|xdebug.remote_host=[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}|xdebug.remote_host='$WSLIP'|" /etc/php/'$PHP_VER'/apache2/conf.d/20-xdebug.ini' >> ~/.bashrc
echo -e "xdebug installed and configured->\n" >>$FILE_LOG

echo -e "<-Install and set up MySQL\n" >>$FILE_LOG
sudo apt -y install mysql-server
sudo chown mysql:mysql -R /var/run/mysqld/
sudo chmod 755 -R /var/run/mysqld/
sudo usermod -d /var/lib/mysql/ mysql
sudo service mysql start
sudo mysql -Bse "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$password_a';"
echo -e "MySQL installed and configured->\n" >>$FILE_LOG

echo -e "<-Install and set up phpmyadmin\n" >>$FILE_LOG
sudo apt install -y phpmyadmin
sudo cat > phpmyadmin.conf<<FILE_TEXT
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
sudo mv phpmyadmin.conf /etc/apache2/conf-available/phpmyadmin.conf
sudo a2enconf phpmyadmin
echo -e "phpmyadmin installed and configured->\n" >>$FILE_LOG

echo -e "<-Create enviroment control file\n" >>$FILE_LOG
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
echo -e "Enviroment control file created->\n" >>$FILE_LOG

echo -e "<-Create Ubuntu maintenance files\n" >>$FILE_LOG
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

sudo chmod 777 dev_env_opt.sh update_ubuntu.sh uninstall_packages.sh
sudo chown $USER: dev_env_opt.sh update_ubuntu.sh uninstall_packages.sh
echo -e "Ubuntu maintenance files created->" >>$FILE_LOG

echo -e "<-Install Python components\n" >>$FILE_LOG
sudo apt -y install python3.10-venv python3-pip
sudo python3 -m venv $PY_VENT_DIR
sudo chown -R $USER: $PY_VENT_DIR
echo -e "Python components installed\n" >>$FILE_LOG

echo -e "<-Install and set up Oracle instant_client\n" >>$FILE_LOG
wget https://download.oracle.com/otn_software/linux/instantclient/219000/instantclient-basic-linux.x64-21.9.0.0.0dbru.zip
wget https://download.oracle.com/otn_software/linux/instantclient/219000/instantclient-sdk-linux.x64-21.9.0.0.0dbru.zip
wget https://download.oracle.com/otn_software/linux/instantclient/219000/instantclient-sqlplus-linux.x64-21.9.0.0.0dbru.zip
sudo unzip instantclient-basic-linux.x64-21.9.0.0.0dbru.zip
sudo unzip instantclient-sdk-linux.x64-21.9.0.0.0dbru.zip
sudo unzip instantclient-sqlplus-linux.x64-21.9.0.0.0dbru.zip
sudo rm instantclient-basic-linux.x64-21.9.0.0.0dbru.zip
sudo rm instantclient-sdk-linux.x64-21.9.0.0.0dbru.zip
sudo rm instantclient-sqlplus-linux.x64-21.9.0.0.0dbru.zip
sudo mkdir /opt/oracle
sudo mv instantclient_21_9 /opt/oracle/instantclient
sudo chown -R root:www-data /opt/oracle/instantclient
#ln -s /opt/oracle/instantclient/libclntsh.so.21.1 /opt/oracle/instantclient/libclntsh.so
#ln -s /opt/oracle/instantclient/libocci.so.21.1 /opt/oracle/instantclient/libocci.so
sudo sh -c "echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf"
sudo ldconfig
sudo pecl channel-update pecl.php.net
sudo pecl config-set php_ini /etc/php/$PHP_VER/apache2/php.ini
sudo pecl install oci8
sudo sed -i 's/;extension=oci8_12c/extension=oci8.so/' "/etc/php/$PHP_VER/apache2/php.ini" #This line is executed due to the error presented in the previous action regarding the php_ini 
sudo chmod 646 /etc/environment /etc/apache2/envvars
sudo echo 'LD_LIBRARY_PATH="opt/oracle/instantclient"' >> /etc/environment
sudo echo 'ORACLE_HOME="opt/oracle/instantclient"' >> /etc/environment
sudo echo 'LD_LIBRARY_PATH="opt/oracle/instantclient"' >> /etc/apache2/envvars
sudo echo 'LD_LIBRARY_PATH="opt/oracle/instantclient"' >> /etc/apache2/envvars
sudo chmod 644 /etc/environment /etc/apache2/envvars
echo -e "Oracle instant_client installed\n" >>$FILE_LOG

echo -e "Restart develope enviroment\n" >>$FILE_LOG
bash ~/dev_env_opt.sh restart