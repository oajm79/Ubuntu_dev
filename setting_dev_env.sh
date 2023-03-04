#!/bin/bash
DATE=$(date +%y%m%d%H%M)
DIR=$(pwd)
FILE_LOG=$DIR/setting_dev_env_$DATE.log
valid_password=false

while read -p "Choose the RDBMS you want to install. Options (1 for MySQL or 2 for MariaDB): " v_rdbms; do
        if [[ "$v_rdbms" =~ ^[12]?$ ]]; then
                if [[ $v_rdbms -eq 1 || -z "$v_rdbms" ]]; then
                    rdbms_name='MySQL'
                    v_rdbms=1
                    while [ "$valid_password" = false ]; do
                        read -s -p "Enter $rdbms_name root password: " password_a 
                        echo
                        read -s -p "Confirm $rdbms_name root password: " password_b
                        if [ "$password_a" == "$password_b" ]; then
                            echo -e "$rdbms_name root password set: ${password_a}\n" >>$FILE_LOG
                            valid_password=true
                            echo
                        fi
                    done
                else
                    rdbms_name='MariaDB'
                    v_rdbms=2
                fi
                break
        else
                echo "The option $v_rdbms is not available"
        fi
done

echo

while read -p "Do you want to install the components (python3.10-venv, python3-pip, python3-django) to create the Python develope enviroment? (Y/N): " valid_yn; do
        if [[ $valid_yn =~ ^[YyNn]?$ ]]; then
                if [ -z $valid_yn ]; then
                        valid_yn="n"
                elif [[ $valid_yn =~ ^[Yy]$ ]]; then
                    read -p "Enter python virtual enviroment name: " python_venv
                    py_venv_dir=$DIR/$python_venv
                fi
                python_venv_install=${valid_yn^^}
                break
        else
                echo "Invalid entry"
        fi
done

echo

while read -p "Do you want to install the components (Oracle Instant Client, OCI8 extension) to connect Oracle databases with PHP? (Y/N): " valid_yn; do
        if [[ $valid_yn =~ ^[YyNn]?$ ]]; then
                if [ -z $valid_yn ]; then
                    valid_yn="n"
                fi
                oracle_php=${valid_yn^^}
                break
        else
                echo "Invalid entry"
        fi
done
echo

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
sudo apt install -y php libapache2-mod-php php-mysql php-xml php-cli php-curl php-zip php-json php-mbstring php-pear php-dev php-ssh2
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

echo -e "<-Install and set up $rdbms_name\n" >>$FILE_LOG
if [ $v_rdbms -eq 1 ]; then 
    sudo apt -y install mysql-server
    sudo chown mysql:mysql -R /var/run/mysqld/
    sudo chmod 755 -R /var/run/mysqld/
    sudo usermod -d /var/lib/mysql/ mysql
    sudo service mysql restart
    sudo mysql -Bse "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$password_a';"
    sudo mysql_secure_installation
else
    sudo apt -y install mariadb-server
    sudo service mariadb restart 
    sudo mysql_secure_installation
fi
echo -e "$rdbms_name installed and configured->\n" >>$FILE_LOG

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
rdbms_name=${rdbms_name,,}
sudo cat > dev_env_opt.sh<<FILE_TEXT
#!/bin/bash
OPTION="\${1^^}"
if [ "\$OPTION" == "START" ]; then
    sudo service apache2 start
    sudo service $rdbms_name start
    source $py_venv_dir/bin/activate 
    cd $py_venv_dir/server
    python manage.py runserver localhost:8000
elif [ "\$OPTION" == "STOP" ]; then
    sudo service apache2 stop
    sudo service $rdbms_name stop
    deactivate
elif [ "\$OPTION" == "RESTART" ]; then
    sudo service apache2 restart
    sudo service $rdbms_name restart
elif [ "\$OPTION" == "STATUS" ]; then
    sudo service apache2 status
    sudo service $rdbms_name status
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

sudo cat > uninstall_dev_env.sh<<FILE_TEXT
#!/bin/bash
sudo apt -y remove phpmyadmin
bash ~/dev_env_opt.sh stop
sudo apt -y remove php apache2 phpmyadmin mysql-server mariadb-server python3.10-venv python3-pip
sudo apt -y autoclean
sudo apt -y purge
sudo pecl uninstall oci8
sudo rm dev_env_opt.sh update_ubuntu.sh uninstall_packages.sh
FILE_TEXT

sudo chmod 777 dev_env_opt.sh update_ubuntu.sh uninstall_packages.sh uninstall_dev_env.sh
sudo chown $USER: dev_env_opt.sh update_ubuntu.sh uninstall_packages.sh uninstall_dev_env.sh
echo -e "Ubuntu maintenance files created->" >>$FILE_LOG

if [ $python_venv_install = 'Y' ]; then
    echo -e "<-Install Python components\n" >>$FILE_LOG
    sudo apt -y install python3.10-venv python3-pip
    sudo python3 -m venv $py_venv_dir
    sudo chown -R $USER: $py_venv_dir
    source $py_venv_dir/bin/activate
    pip install django
    cd $py_venv_dir
    django-admin startproject server
    cd server
    python manage.py migrate
    python manage.py createsuperuser
    sudo cat > settings.py<<FILE_TEXT
    ALLOWED_HOSTS = ['localhost']
FILE_TEXT
    sudo ufw allow 8000
    deactivate
    cd ~/
    echo -e "Python components installed\n" >>$FILE_LOG
fi

echo

if [ $oracle_php = 'Y' ]; then
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
    sudo echo 'export LD_LIBRARY_PATH="opt/oracle/instantclient"' >> /etc/apache2/envvars
    sudo echo 'export ORACLE_HOME="opt/oracle/instantclient"' >> /etc/apache2/envvars
    sudo chmod 644 /etc/environment /etc/apache2/envvars
    echo -e "Oracle instant_client installed\n" >>$FILE_LOG
fi

echo -e "Restart develope enviroment\n" >>$FILE_LOG
bash ~/dev_env_opt.sh restart