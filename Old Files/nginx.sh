#!/bin/bash

clear
echo "========================================================================="
echo "Nginx Frontend plugin for LLsMP 0.5 Written by w0w.me"
echo "========================================================================="
echo "LLsMP is A tool to auto-compile & install Litespeed+MySQL+PHP on Linux "
echo ""
echo "For more information please visit http://llsmp.org/"
echo "========================================================================="
echo ""

check_installed()
{
version=$(cat /root/llsmp/.installed)
if [ "$version" = "LLsMP 0.5 CentOS" ];then
echo "========================================================================="
echo "LNLsMP installtion is being started" 
echo "========================================================================="
else
echo "LLsMP 0.5 Centos have not been installed"
exit 1
fi
}

check_installed

if [ -f /etc/init.d/nginx ];then
echo "Which site would you upgrade to lnlsmp?"
domain_list=$(cd /home/wwwroot/ && ls )
echo $domain_list | sed "s/ \{1,\}/\n/g"
printf "Please input the full domain:"
read domain
nginx_domain_list=$(cat /usr/local/lsws/conf/httpd_config.xml | grep \<domain\>$domain | awk '{print $1}' | sed 's/<domain>//g' | sed 's/<\/domain>//g' | sed 's/\,/ /g')
cat >>/etc/nginx/conf.d/$domain.conf<<EOF
server {
listen       80;
server_name  $nginx_domain_list;
try_files \$uri @backend;
                error_page 400 401 402 403 404 405 406 407 408 409 500 501 502 503 504 @backend;
                location @backend {
                proxy_pass http://127.0.0.1:81;
                include proxy.conf;
                }
location / {
root   /home/wwwroot/$domain/html;
index  index.html index.htm index.php;
}
location ~ \.php\$ {
        proxy_pass http://127.0.0.1:81;
        include proxy.conf;
}
}
EOF
/etc/init.d/nginx restart
echo "========================================================================="
echo "Done"
echo "For more information, please visit LLsMP.org"
echo "========================================================================="

#Start Installtion
else 
	get_char()
	{
	SAVEDSTTY=`stty -g`
	stty -echo
	stty cbreak
	dd if=/dev/tty bs=1 count=1 2> /dev/null
	stty -raw
	stty echo
	stty $SAVEDSTTY
	}
	echo ""
	echo "Press any key to start installation or CTRL+C to cancel."
	char=`get_char`
#Change Litespeed port
port="<address>\*:80<\/address>"
new_port="<address>\*:81<\/address>"
cp /usr/local/lsws/conf/httpd_config.xml /usr/local/lsws/conf/httpd_config.xml.bak
sed -i 's/'$port'/'$new_port'/g' /usr/local/lsws/conf/httpd_config.xml
/etc/init.d/lsws restart

#Install nginx
yum install nginx -y 
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
cat >> /etc/nginx/nginx.conf <<EOF
user              nginx;
worker_processes  4;

error_log  /var/log/nginx/error.log;
#error_log  /var/log/nginx/error.log  notice;
#error_log  /var/log/nginx/error.log  info;

pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    gzip on;
    include conf.d/*.conf;

}
EOF

cat >>/etc/nginx/proxy.conf<<EOF
proxy_redirect          off;
proxy_set_header        Host \$host;
proxy_set_header        X-Real-IP \$remote_addr;
proxy_set_header        X-Forwarded-For   \$proxy_add_x_forwarded_for;
client_max_body_size    50m;
client_body_buffer_size 256k;
proxy_connect_timeout   30;
proxy_send_timeout      30;
proxy_read_timeout      60;

proxy_buffer_size       4k;
proxy_buffers           4 32k;
proxy_busy_buffers_size 64k;
proxy_temp_file_write_size 64k;
proxy_next_upstream error timeout invalid_header http_500 http_503 http_404;
proxy_max_temp_file_size 128m;

#Nginx cache
client_body_temp_path client_body 1 2;
proxy_temp_path proxy_temp 1 2;

#client_body_temp_path      /tmpfs/client_body_temp 1 2;
#proxy_temp_path            /tmpfs/proxy_temp 1 2;
#fastcgi_temp_path          /tmpfs/fastcgi_temp 1 2;
EOF

cat >> /etc/nginx/conf.d/default.conf <<EOF
server {
listen       81;
server_name  _;
try_files \$uri @backend;
                error_page 400 401 402 403 404 405 406 407 408 409 500 501 502 503 504 @backend;
                location @backend {
                proxy_pass http://127.0.0.1:81;
                include proxy.conf;
                }
location / {
root   /usr/local/lsws/DEFAULT/html;
index  index.html index.htm index.php;
}
location ~ \.php\$ {
        proxy_pass http://127.0.0.1:81;
        include proxy.conf;
}
}
EOF

/etc/init.d/nginx restart

echo "========================================================================="
echo "Nginx has been installed."
echo "Please run "sh /root/llsmp/nginx.sh" to upgrade website to LNLsMP"
echo "For more information, please visit LLsMP.org"
echo "========================================================================="
fi