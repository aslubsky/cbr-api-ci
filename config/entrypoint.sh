#!/bin/bash

service mysql restart
#service elasticsearch restart
service redis-server restart
service clickhouse-server restart

supervisord -c /etc/supervisor/supervisord.conf

mysql -uroot -ptests -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'tests';"

echo "Ready for start"
