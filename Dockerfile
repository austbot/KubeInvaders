FROM  nginx

# Install kubectl
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# Install Openresty
RUN apt-get update
RUN apt-get -y install --no-install-recommends wget gnupg ca-certificates jq openssl task-spooler at
RUN wget -O - https://openresty.org/package/pubkey.gpg | apt-key add -
RUN codename=`grep -Po 'VERSION="[0-9]+ \(\K[^)]+' /etc/os-release` && echo "deb http://openresty.org/package/debian $codename openresty" | tee /etc/apt/sources.list.d/openresty.list
RUN apt-get update
RUN apt-get -y install openresty luarocks
RUN chmod 777 /usr/local/openresty/nginx
RUN apt-get -y install openresty luarocks libssl-dev git vim lua-json lua-socket
RUN luarocks install luasec 
RUN luarocks install lunajson

# Install kube-linter
RUN curl -L -O https://github.com/stackrox/kube-linter/releases/download/0.1.5/kube-linter-linux.tar.gz
RUN tar -xvf kube-linter-linux.tar.gz
RUN rm -f kube-linter-linux.tar.gz
RUN cp  kube-linter /usr/local/bin/
RUN chmod 775 /usr/local/bin/kube-linter
COPY kube-linter/kube-linter-parser.sh /opt/kube-linter-parser.sh
RUN chmod +x /opt/kube-linter-parser.sh

# Install game part
COPY ./html5 /var/www/html

# Install Redis
RUN apt-get install redis -y
COPY redis/redis.conf /etc/redis/redis.conf

# Configure Nginx
RUN sed -i.bak 's/listen\(.*\)80;/listen 8081;/' /etc/nginx/conf.d/default.conf

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/metrics.lua /tmp/metrics.lua
COPY nginx/pod.lua /tmp/pod.lua
COPY nginx/node.lua /tmp/node.lua
COPY chaos-node/chaos-node.lua /tmp/chaos-node.lua

COPY nginx/KubeInvaders.conf /etc/nginx/conf.d/KubeInvaders.conf
RUN chmod g+rwx /var/cache/nginx /var/run /var/log/nginx /var/www/html /etc/nginx/conf.d

EXPOSE 8080

ENV PATH=/usr/local/openresty/nginx/sbin:$PATH
COPY ./entrypoint.sh /
RUN chmod a+rwx ./entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
