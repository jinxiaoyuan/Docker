#!/bin/bash
# Create by Jin Xiaoyuan at 2016-07-15 11:03

if [[ x$1 == "x" ]]; then
    echo "Notice: domain_or_ip not specified, using default: pool.docker.gzts.com"
    sleep 2
fi

domain=${1:-pool.docker.gzts.com}
crt_key_name="${domain}-key.pem"
crt_name="${domain}.crt"
env_file="registry_docker.env"

base_dir=$(cd $(dirname $0)&&pwd)
cd ${base_dir}

if ! [[ -s certs/ca.crt && -s certs/${crt_key_name} && -s certs/${crt_name} ]]; then
   sh gen_ssl_cert.sh ${domain} || exit 1
fi

registry_dir="/opt/registry"
app_dir="/data/apps/docker_registry"
mkdir -p ${app_dir}/data

cat <<EOF > ${env_file}
# location of registry data
REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=${registry_dir}/data
RGISTRY_STORAGE_DELETE_ENABLED=true

# location of TLS key/cert
REGISTRY_HTTP_TLS_KEY=${registry_dir}/certs/${crt_key_name}
REGISTRY_HTTP_TLS_CERTIFICATE=${registry_dir}/certs/${crt_name}
# location of CA of trusted clients
REGISTRY_HTTP_TLS_CLIENTCAS_0=${registry_dir}/certs/ca.crt
EOF


scp -r certs ${env_file} ${app_dir}/

/usr/bin/docker kill ${domain}
/usr/bin/docker rm ${domain}
/usr/bin/docker run -d --restart=on-failure:10 -p 443:5000 -v ${app_dir}:${registry_dir} --env-file ${app_dir}/${env_file} --name ${domain} registry:2


client_ca_dir="/etc/docker/certs.d/${domain}"
mkdir -p ${client_ca_dir} && scp certs/ca.crt ${client_ca_dir}
