#!/bin/bash

# Header
echo ""
echo ""
echo ""
echo ""
echo "######################################################"
echo "#         MariaDB Security Audit v0.1 Begin          #"
echo "######################################################"
echo ""

# Credentials
echo ""
echo -n "Enter your MariaDB username and press [ENTER]: "
read username
echo ""
echo -n "Enter the password for $username and press [ENTER]: "
read -s password
echo ""

# Find all user, host combos
echo ""
echo ""
echo "######################################################"
echo "#                    All Users                       #"
echo "######################################################"
echo ""
echo "The following users were found."
echo "It is recommended to regularly review this list and"
echo "remove users which are no longer needed."
mysql -u "$username" -p"$password" -e "SELECT user, host FROM mysql.user WHERE is_role = 'N' ORDER BY user, host"

# all roles
role_count=$(mysql -u "$username" -p"$password" -BNe "SELECT COUNT(*) FROM mysql.user WHERE is_role = 'Y' ")
if [ "$role_count" -gt 0 ] ; then
    echo ""
    echo ""
    echo "######################################################"
    echo "#                    All Roles                       #"
    echo "######################################################"
    echo ""
    echo "The following roles were found."
    echo "It is recommended to regularly review this list and"
    echo "remove roles which are no longer needed."
    mysql -u "$username" -p"$password" -e "SELECT user AS role_name FROM mysql.user WHERE is_role = 'Y' "
fi

# Users without passwords
wopass_count=$(mysql -u "$username" -p"$password" -BNe "SELECT COUNT(*) FROM mysql.user WHERE password = '' AND is_role = 'N' ")
if [ "$wopass_count" -gt 0 ] ; then
    echo ""
    echo ""
    echo "######################################################"
    echo "#              Users Without Passwords               #"
    echo "######################################################"
    echo ""
    echo "The following users have no password set."
    echo "All users should have a password."
    mysql -u "$username" -p"$password" -e "SELECT user, host FROM mysql.user WHERE is_role = 'N' AND password = '' ORDER BY user, host"
    echo ""
    echo "Use ALTER USER ... SET PASSWORD ... to set a password"
    echo "for each user."
fi

# Anonymous users
anonymous_count=$(mysql -u "$username" -p"$password" -BNe "SELECT COUNT(*) FROM mysql.user where user = '' ")
if [ "$anonymous_count" -gt 0 ] ; then
    echo ""
    echo ""
    echo "######################################################"
    echo "#                 Anonymous Users                    #"
    echo "######################################################"
    echo ""
    echo "The following anonymous accounts were found."
    echo "It is recommended to drop all anonymous users."
    mysql -u "$username" -p"$password" -e "SELECT user, host FROM mysql.user WHERE is_role = 'N' AND user = '' ORDER BY host"
    echo ""
    echo "Use DROP USER to drop these anonymous users."
fi

# Root users
root_cnt=$(mysql -u "$username" -p"$password" -BNe "SELECT COUNT(*) FROM mysql.user WHERE user = 'root' ")
if [ "$root_cnt" -gt 0 ] ; then
    echo ""
    echo ""
    echo "######################################################"
    echo "#                    Root Users                      #"
    echo "######################################################"
    echo ""
    echo "The following root accounts were found."
    echo "It is recommended to rename root users."
    mysql -u "$username" -p"$password" -e "SELECT user, host FROM mysql.user WHERE is_role = 'N' AND user = 'root' ORDER BY host"
    echo ""
    echo "Use RENAME USER command to rename the above users."
fi

# Excessive privileges
echo ""
echo ""
echo "######################################################"
echo "#               Excessive Privileges                 #"
echo "######################################################"
echo ""
echo "The following users with global privileges were found."
echo "It is recommended to review these users and verify."
mysql -u "$username" -p"$password" -e "SELECT user, host, super_priv, shutdown_priv, drop_priv, alter_priv FROM mysql.user WHERE is_role = 'N' ORDER BY user, host" 
echo ""

# skip_name_resolve
# show global variables like 'skip_name_resolve'; OFF
skip_name_resolve=$(mysql -u "$username" -p"$password" -BNe "SHOW GLOBAL VARIABLES LIKE 'skip_name_resolve';" | awk '{ print $2 }')
if [ "$skip_name_resolve" != 'ON' ] ; then
    echo ""
    echo ""
    echo "######################################################"
    echo "#                Skip Name Resolve                   #"
    echo "######################################################"
    echo ""
    echo "skip_name_resolve is not enabled."
    echo "It is recommended to enable this variable in order to"
    echo "disable hostname lookups."
    echo "skip_name_resolve = 1"
fi

# local_infile
local_infile=$(mysql -u "$username" -p"$password" -BNe "SHOW GLOBAL VARIABLES LIKE 'local_infile';" | awk '{ print $2 }')
if [ "$local_infile" != 'OFF' ] ; then
    echo ""
    echo ""
    echo "######################################################"
    echo "#                   Local Infile                     #"
    echo "######################################################"
    echo ""
    echo "local_infile is currently enabled. It is recommended"
    echo "to disable this functionality."
    echo "local_infile = 0"
fi

# have_symlink
have_symlink=$(mysql -u "$username" -p"$password" -BNe "SHOW GLOBAL VARIABLES LIKE 'have_symlink';" | awk '{ print $2 }')
if [ "$have_symlink" != 'DISABLED' ] ; then
    echo ""
    echo ""
    echo "######################################################"
    echo "#                Skip Name Resolve                   #"
    echo "######################################################"
    echo ""
    echo "Symlinks are currently enabled. It is recommended to "
    echo "disable."
    echo "skip_name_resolve = 1"
fi

# bind address
bind_address_cnt=$(cat /etc/my.cnf.d/* | grep "bind" | wc -l)
if [ "$bind_address_cnt" -eq 0 ] ; then
    echo ""
    echo ""
    echo "######################################################"
    echo "#                  Bind Address                      #"
    echo "######################################################"
    echo ""
    echo "bind_address does not appear to be set, allowing"
    echo "MariaDB to listen on all available addresses. It is"
    echo "recommended to bind to a specific address, preferably"
    echo "an internal address."
    echo "bind_address = XXX.XXX.XXX.XXX"
fi

# port
port=$(mysql -u "$username" -p"$password" -BNe "SHOW GLOBAL VARIABLES LIKE 'port';" | awk '{ print $2 }')
if [ "$port" -eq 3306 ] ; then
    echo ""
    echo ""
    echo "######################################################"
    echo "#                  Default Port                      #"
    echo "######################################################"
    echo ""
    echo "The default port, 3306, is currently being used. It is"
    echo "recommended to change the port which MariaDB listens."
    echo "port = XXXXX"
fi

# server audit logging plugin
audit_plugin_cnt=$(mysql -u "$username" -p"$password" -BNe "SELECT COUNT(*) FROM information_schema.all_plugins WHERE plugin_name = 'SERVER_AUDIT' ")
if [ "$audit_plugin_cnt" -eq 0 ] ; then
    echo ""
    echo ""
    echo "######################################################"
    echo "#                  Audit Plugin                      #"
    echo "######################################################"
    echo ""
    echo "The MariaDB Audit Plugin is not installed. It is"
    echo "recommended to install."
    echo "INSTALL PLUGIN server_audit SONAME 'server_audit';"

fi

# simple password check plugin
audit_plugin_cnt=$(mysql -u "$username" -p"$password" -BNe "SELECT COUNT(*) FROM information_schema.all_plugins WHERE plugin_name = 'simple_password_check' ")
if [ "$audit_plugin_cnt" -eq 0 ] ; then
    echo ""
    echo ""
    echo "######################################################"
    echo "#          Simple Password Check Plugin              #"
    echo "######################################################"
    echo ""
    echo "The Simple Password Check plugin is not installed. It"
    echo "is recommended to install and configure."
    echo "INSTALL SONAME 'simple_password_check';"
fi

# Footer
echo ""
echo "######################################################"
echo "#         MariaDB Security Audit v0.1 End            #"
echo "######################################################"
echo ""
echo ""
echo ""
echo ""

# Clear
username=
password=

exit 0
