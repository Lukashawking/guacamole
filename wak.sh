clear ; echo "Instalado los requerimientos" ; sleep 5
# Install dependencies
apt update; \
apt install -y --no-install-recommends \
libcairo2-dev libjpeg62-turbo-dev libpng-dev \
libossp-uuid-dev libavcodec-dev libavutil-dev \
libswscale-dev freerdp2-dev libfreerdp-client2-2 libpango1.0-dev \
libssh2-1-dev  libtelnet-dev  libvncserver-dev \
libpulse-dev libssl-dev libvorbis-dev libwebp-dev libwebsockets-dev \
adduser build-essential  libtool-bin  libavformat-dev \
ghostscript postgresql-${PG_MAJOR} \
&& rm -rf /var/lib/apt/lists/*
apt install openjdk-11-jdk -y

useradd -m -U -d /opt/tomcat -s /bin/false tomcat

clear  ; echo "Instalando Tomcat 9.0.54" ; sleep 5

cd /opt/
mkdir tomcat
cd tomcat
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.54/bin/apache-tomcat-9.0.54.tar.gz
tar -zvxf apache-tomcat-9.0.54.tar.gz
rm -f apache-tomcat-9.0.54.tar.gz
 mv apache-tomcat-9.0.54 tomcatapp
 chown -R tomcat: /opt/tomcat
 chmod +x /opt/tomcat/tomcatapp/bin/*.sh


cat > /etc/systemd/system/tomcat.service  << EOF
[Unit]
Description=Tomcat 9.0.54 servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"

Environment="CATALINA_BASE=/opt/tomcat/tomcatapp"
Environment="CATALINA_HOME=/opt/tomcat/tomcatapp"
Environment="CATALINA_PID=/opt/tomcat/tomcatapp/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/tomcatapp/bin/startup.sh
ExecStop=/opt/tomcat/tomcatapp/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF



cd /tmp


# Install guacamole-server
VER=1.3.0
clear  ; echo "Descargando y compilando la version $VER de guacamole server" ; sleep 5

wget https://downloads.apache.org/guacamole/$VER/source/guacamole-server-$VER.tar.gz

tar -xvzf guacamole-server-$VER.tar.gz

cd guacamole-server-$VER

./configure --with-init-dir=/etc/init.d

make -j $(nproc)
make install
ldconfig

mkdir /etc/guacamole
echo "GUACAMOLE_HOME=/etc/guacamole" | tee -a /etc/default/tomcat

cat > /etc/guacamole/guacamole.properties << EOF
guacd-hostname: localhost
guacd-port:    4822
user-mapping:    /etc/guacamole/user-mapping.xml
EOF

cat > /etc/guacamole/user-mapping.xml << EOF
<user-mapping>
        
    <!-- Per-user authentication and config information -->

    <!-- A user using md5 to hash the password
         guacadmin user and its md5 hashed password below is used to 
             login to Guacamole Web UI-->
    <authorize 
            username="admin"
            password="admin">

        <connection name="ejemplo de conexion ssh en archivo /etc/guacamole/user-mapping.xml ">
            <protocol>ssh</protocol>
            <param name="hostname">192.168.1.254</param>
            <param name="username">root</param>
            <param name="password">TuClave</param>
            <param name="port">22</param>
        </connection>

        
        <connection name="ejemplo RDP Windows Terminal en /etc/guacamole/user-mapping.xml">
            <protocol>rdp</protocol>
            <param name="hostname">192.168.1.10</param>
            <param name="port">3389</param>
            <param name="username">Administrador</param>
            <param name="ignore-cert">true</param>
        </connection>

    </authorize>

</user-mapping>
EOF

ln -s /etc/guacamole /opt/tomcat/tomcatapp/.guacamole


wget https://downloads.apache.org/guacamole/$VER/binary/guacamole-$VER.war -O /opt/tomcat/tomcatapp/webapps/guacamole.war

clear  ; echo "Arrancando y activando servicios de systemctl para tomcat y guacamole" ; sleep 5

systemctl daemon-reload
systemctl start tomcat guacd
/lib/systemd/systemd-sysv-install enable guacd
systemctl enable  tomcat guacd

clear
echo "http://IP:8080/guacamole"
echo "usuario y clave admin, para cambiar la clave"
echo ""
echo "Script por Kamus vargas"
echo ""

