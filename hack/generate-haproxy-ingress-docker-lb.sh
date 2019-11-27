#!/usr/bin/env bash
# Create a kustomization.yaml and then add all kubernetes YAMLs into resources...
set -o errexit
set -o nounset
set -o pipefail

# TODO: auto update /etc/hosts with IPs for easy demo

HAPROXY_CONFIG="haproxy.cfg"

# get nodes IPs for subing in
NAME_INGRESS_NODES="$(kubectl get nodes -l ingress=true -o=custom-columns=:.metadata.name)"

# 443 block
INGRESS_BACKEND_BLOCK=$(for host in $NAME_INGRESS_NODES; do echo "  server ${host} $(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${host}):30443 check check-ssl verify none"; done)


cat << EOF > haproxy.cfg
# last updated by $0 on $(date +%F)
global
  log /dev/log local0
  log /dev/log local1 notice
  daemon

defaults
  log global
  mode tcp
  option dontlognull
  # TODO: tune these
  timeout connect 5000
  timeout client 50000
  timeout server 50000

frontend http-frontend
    bind *:80
    mode http
    redirect scheme https if !{ ssl_fc }

frontend https-frontend
  bind *:443
  default_backend nginx-ingress-nodes

backend nginx-ingress-nodes
  balance roundrobin
$INGRESS_BACKEND_BLOCK
EOF

#docker rm -f haproxy-nginx-ingress
docker run -t -i -d --name haproxy-nginx-ingress -v /dev/log:/dev/log --mount type=bind,src=`pwd`/haproxy.cfg,dst=/usr/local/etc/haproxy/haproxy.cfg haproxy:2.1-alpine haproxy -f /usr/local/etc/haproxy/haproxy.cfg


HAPROXY_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' haproxy-nginx-ingress)

echo "
Complete: HAproxy is running...

!!!!!!!!! HA PROXY SETUP !!!!!!!!!

HAPROXY INTERNAL IP: ${HAPROXY_IP}

TEST WITH:
curl -k https://${HAPROXY_IP}
default backend - 404

ADD ENTRIES TO /ETC/HOSTS:
echo \"${HAPROXY_IP} coolsite.kopish.dev\" | sudo tee --append /etc/hosts

ping coolsite.kopish.dev

TO DEBUG: docker exec -it haproxy-nginx-ingress sh
or run command without "-d"
`docker run -t -i --name haproxy-nginx-ingress -v /dev/log:/dev/log --mount type=bind,src=`pwd`/haproxy.cfg,dst=/usr/local/etc/haproxy/haproxy.cfg haproxy:2.1-alpine haproxy -f /usr/local/etc/haproxy/haproxy.cfg`

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"
