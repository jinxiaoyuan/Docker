#!/bin/bash

if [[ x$1 == "x" ]]; then
    echo "Notice: domain_or_ip not specified, using default: pool.docker.gzts.com"
    sleep 2
fi

domain=${1:-pool.docker.gzts.com}
crt_key_name="${domain}-key.pem"
crt_name="${domain}.crt"


base_dir=$(cd $(dirname $0)&&pwd)
cd ${base_dir}
mkdir -p data

serv_file="docker_registry@.service"
env_file="registry_docker.env"
serv_inst=${serv_file/@/@${domain}}

if ! [[ -s certs/ca.crt && -s certs/${crt_key_name} && -s certs/${crt_name} ]]; then
   sh gen_ssl_cert.sh ${domain} || exit 1
fi

registry_dir="/opt/registry"
app_dir="/data/apps/docker_registry"
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

cat <<EOF > ${serv_file}
[Unit]
Description=Docker Registry %i
After=docker.service
Requires=docker.service
[Service]
Restart=on-failure
RestartSec=100s
TimeoutStartSec=0
Environment=BASEDIR=${app_dir}
ExecStartPre=-/usr/bin/docker kill %i
ExecStartPre=-/usr/bin/docker rm %i
ExecStart=/usr/bin/docker run -p 443:5000 -v ${BASEDIR}:${registry_dir} --env-file ${BASEDIR}/${env_file} --name %i registry:2
ExecStop=/usr/bin/docker kill %i
[X-Fleet]
# Don't schedule on the same machine as other registry instances
Conflicts=%p@*.service
# or you can specify a particular machine
# MachineID=72f6e393
EOF

# machine_id=$(awk -F= '/^MachineID=/{print $2}' ${serv_file})
fleetctl load ${serv_inst}
machine_ip=$(fleetctl list-units | awk "/^${serv_inst}/"'{print $2}'| awk -F/ '{print $2}')
fleetctl ssh ${serv_inst} "sudo mkdir -p ${app_dir} && sudo chown -R ${USER}.${USER} ${app_dir}"
scp -r -o StrictHostKeyChecking=no ${base_dir}/* ${machine_ip}:${app_dir}/

client_ca_dir="/etc/docker/certs.d/${domain}"
sudo mkdir -p ${client_ca_dir} && sudo cp certs/ca.crt ${client_ca_dir}

fleetctl start ${serv_inst}

echo "Docker registry instance(${serv_inst}) had deployed on server ${machine_ip}"
echo "You can manage the registry service using fleetctl from mow on."
echo "You mush bind your domain(${domain}) to server(${machine_ip}) to use the registry"
echo "For client use we must make our CA to be trusted by copy the CA(certs/ca.crt) to ${client_ca_dir}"
