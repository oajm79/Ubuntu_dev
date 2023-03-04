# Developer environment deployer
Program to generate a functional WSL development environment on the Ubuntu 22.04 distribution

<h1>This shell script implements the following items:</h1>

<ul>
    <li>Apache</li>
    <li>PHP</li>
    <li>MySQL or MariaDB</li>
    <li>phpMyAdmin</li>
    <li>Python Virtual Enviroment (Python is already installed on Ubuntu distribution)</li>
    <li>Django</li>
    <li>Oracle Instant Client</li>
</ul>

It is assumed that before running this deployment, Ubuntu is already installed and running. This deployer was tested in a WSL environment.

<h1>How to use:</h1>
<ol>
    <li>Copy the setting_dev_env.sh file to the Ubuntu user path</li>
    <li>Assign execution permissions to the file: <code>sudo chmod 777 setting_dev_env.sh</code></li>
    <li>Execute the file: <code>./setting_dev_env.sh</code></li>
    <li>Set the MySQL password for root:
    </li>
        <img src="inc\mysqlrootpsw.png">
    <li>Set the Python virtual enviroment name:
    </li>
        <img src="inc\pyenvname.png">
    <li>During the phpMyadmin installation, user intervention will be requested to select the web server to be configured. Choose the option as the image below:
    <img src="inc\phpmyadmin_apache.png">
    </li>
    <li>It will also be necessary to select the type of configuration for phpMyadmin and MySQL. Choose the option as the image below:
        <img src="inc\phpmyadmin_mysql.png">
    </li>
    <li>During the installation of the OCI8 complement you must enter the folder where the Oracle instant_cliente is installed. Copy this <code>instantclient,/opt/oracle/instantclient</code> and paste at terminal: 
        <img src="inc\oci8.png">
    </li>
    <li>Let the execution end and its development environment will be installed correctly</li>
</ol>

<h1>Check your enviroment:</h1>

<ol>
    <li>This is the apache server address: <a href="http://localhost:8081">http://localhost:8081</a>
    </li>
        <img src="inc\apache.png">
    <li>This is the phpMyadmin address: <a href="http://localhost:8081/phpmyadmin">http://localhost:8081/phpmyadmin</a></li>
        <img src="inc\phpmyadmin.png">
    <li>This is the php config address: <a href="http://localhost:8081/phpinfo.php">http://localhost:8081/phpinfo.php</a></li>
        <img src="inc\PHP.png">
        <img src="inc\php_oci8.png">
        <img src="inc\php_xdebug.png">
</ol>

