FROM proftpd

ARG COUNTRY_NAME=FR
ARG STATE="\ "
ARG LOCALITY_NAME=LILLE
ARG ORGANIZATION_NAME=DOCKER
ARG COMMON_NAME=ARNAUD

RUN apt update \
&& apt-get install -y openssl jenkins \
# TLS SSL FTP
# Primary reference source: https://docs.docker.com/engine/swarm/configs/
# Création d'une root key
&& openssl genrsa -out "root-ca.key" 4096 \
# Création d'un CSR (Certificate Signing Request) à partir de la root key
&& openssl req -new -key "root-ca.key" -out "root-ca.csr" -sha256 -subj "/C=${COUNTRY_NAME}/ST=\ /L=${LOCALITY_NAME}/O=${ORGANIZATION_NAME}/CN=${COMMON_NAME}" \
# Configuration du root CA (Certificate Authority)
&& touch root-ca.cnf \
&& echo "[root_ca]" >> root-ca.cnf \
&& echo "basicConstraints = critical,CA:TRUE,pathlen:1" >> root-ca.cnf \
&& echo "keyUsage = critical, nonRepudiation, cRLSign, keyCertSign" >> root-ca.cnf \
&& echo "subjectKeyIdentifier=hash" >> root-ca.cnf \
# Signature du certificat
&& openssl x509 -req -days 3650 -in "root-ca.csr" -signkey "root-ca.key" -sha256 -out "root-ca.crt" -extfile "root-ca.cnf" -extensions root_ca \
# Génération de la clef de site
&& openssl genrsa -out "site.key" 4096 \
# Génération du certificat du site et signature avec la clef de site
&& openssl req -new -key "site.key" -out "site.csr" -sha256 -subj "/C=${COUNTRY_NAME}/ST=\ /L=${LOCALITY_NAME}/O=${ORGANIZATION_NAME}/CN=localhost" \
&& touch site.cnf \
&& echo "[server]" >> site.cnf \
&& echo "authorityKeyIdentifier=keyid,issuer" >> site.cnf \
&& echo "basicConstraints = critical,CA:FALSE" >> site.cnf \
&& echo "extendedKeyUsage=serverAuth" >> site.cnf \
&& echo "keyUsage = critical, digitalSignature, keyEncipherment" >> site.cnf \
&& echo "subjectAltName = DNS:localhost, IP:127.0.0.1" >> site.cnf \
&& echo "subjectKeyIdentifier=hash" \
# Signature du certificat du site
&& openssl x509 -req -days 750 -in "site.csr" -sha256 -CA "root-ca.crt" -CAkey "root-ca.key" -CAcreateserial -out "site.crt" -extfile "site.cnf" -extensions server \
# ??? Protection de root-ca.key nécessaire ???
# PROFTPD
&& touch proftpd.conf \
&& echo "ServerName ProFTPD Default Installation" >> proftpd.conf \
&& echo "ServerType standalone" >> proftpd.conf \
&& echo "DefaultServer  on" >> proftpd.conf \
&& echo "" >> proftpd.conf \
&& echo "Port   21" >> proftpd.conf \
&& echo "" >> proftpd.conf \
&& echo "Umask  022" >> proftpd.conf \
&& echo "" >> proftpd.conf \
&& echo "MaxInstances   30" >> proftpd.conf \
&& echo "" >> proftpd.conf \
&& echo "User   nobody" >> proftpd.conf \
&& echo "Group  nogroup" >> proftpd.conf \
&& echo "" >> proftpd.conf \
&& echo "DefaultRoot ~" >> proftpd.conf \
&& echo "" >> proftpd.conf \
&& echo "<Directory />" >> proftpd.conf \
&& echo "   AllowOverwrite  on" >> proftpd.conf \
&& echo "</Directory>" >> proftpd.conf \
&& echo "" >> proftpd.conf \
&& echo "<Anonymous ~ftp>" >> proftpd.conf \
&& echo "   User    ftp" >> proftpd.conf \
&& echo "   Group   ftp" >> proftpd.conf  \
&& echo "" >> proftpd.conf \
&& echo "   UserAlias  anonymous ftp" >> proftpd.conf \
&& echo "" >> proftpd.conf \
&& echo "   MaxClients  10" >> proftpd.conf \
&& echo "" >> proftpd.conf \
&& echo "   DisplayLogin    welcome.msg" >> proftpd.conf \
&& echo "   DisplayFirstChdir   .message" >> proftpd.conf \
&& echo "" >> proftpd.conf \ 
&& echo "   <Limit WRITE>" >> proftpd.conf \
&& echo "       DenyAll" >> proftpd.conf \
&& echo "   </Limit>" >> proftpd.conf \
&& echo "</Anonymous>" >> proftpd.conf \
&& touch sftp.conf \
&& echo "<IfModule mod_sftp.c>" >> sftp.conf \
&& echo "" >> sftp.conf \
&& echo "   SFTPEngine on" >> sftp.conf \
&& echo "   Port 2222" >> sftp.conf \
&& echo "   SFTPLog /var/log/proftpd/sftp.log" >> sftp.conf \
&& echo "" >> sftp.conf \
&& echo "   SFTPHostKey /etc/ssh/ssh_host_rsa_key" >> sftp.conf \
&& echo "   SFTPHostKey /etc/ssh/ssh_host_dsa_key" >> sftp.conf \
&& echo "" >> sftp.conf \
&& echo "   SFTPAuthMethods publickey" >> sftp.conf \
&& echo "" >> sftp.conf \
&& echo "   SFTPAuthorizedUserKeys file:/etc/proftpd/authorized_keys/%u" >> sftp.conf \    
&& echo "   SFTPCompression delayed" >> sftp.conf \
&& echo "" >> sftp.conf \
&& echo "</IfModule>" >> sftp.conf \
# JENKINS
&& useradd -m jenkins \
&& mkdir /home/jenkins/cgi-bin \
&& mkdir /home/jenkins/artifacts \
# archiveArtifacts:
# build/libs/**/*.jar
# defaultroot ~
# Donner l'autorisation d'écrire seulement à l'utilisateur Jenkins
&& start jenkins

# COPY

# VOLUME

# WORKDIR

# CMD start proftpd

# EXPOSE