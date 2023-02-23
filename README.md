# Developer environment deployer
Program to generate a functional WSL development environment on the Ubuntu 22.04 distribution

<h1>This shell script implements the following items:</h1>

<ul>
    <li>Apache</li>
    <li>PHP</li>
    <li>MySQL</li>
    <li>phpMyAdmin</li>
    <li>Python Virtual Enviroment (Python is already installed on Ubuntu distribution)</li>
    <li>Oracle Instant Client</li>
</ul>

It is assumed that before running this deployment, Ubuntu is already installed and running. This deployer was tested in a WSL environment.

<h1>How to use:</h1>
<ol>
    <li>Copy the setting_dev_env.sh file to the Ubuntu user path</li>
    <li>Assign execution permissions to the file: <code>sudo chmod 777 setting_dev_env.sh</code></li>
    <li>Execute the file: <code>./setting_dev_env.sh</code></li>
    <li>Set the MySQL password for root:</li>
        <img src="inc\mysqlrootpsw.png">
    <li>Set the Python virtual enviroment name:</li>
        <img src="inc\pyenvname.png">
    <li>Let the execution finish</li>
    
</ol>