#!/bin/bash

if [[ x$1 == "x" ]]; then
    echo "Notice: domain_or_ip not specified, using default: pool.docker.gzts.com"
    sleep 2
fi

domain=${1:-pool.docker.gzts.com}


base_dir=$(cd $(dirname $0)&&pwd)
cd ${base_dir}
mkdir -p data

serv_file="docker_registry@.service"
serv_inst=${serv_file/@/@${domain}}

if ! [[ -s certs/ca.crt && -s certs/cert-key.pem && -s certs/cert.crt ]]; then
   sh gen_ssl_cert.sh ${domain} || exit 1
fi

app_dir=$(awk -F= '/^Environment=BASEDIR=/{print $3}' ${serv_file})
# machine_id=$(awk -F= '/^MachineID=/{print $2}' ${serv_file})
fleetctl load ${serv_inst}
machine_ip=$(fleetctl list-units | awk "/^${serv_inst}/"'{print $2}'| awk -F/ '{print $2}')
fleetctl ssh ${serv_inst} "sudo mkdir -p ${app_dir} && sudo chown -R ${USER}.${USER} ${app_dir}"
scp -r -o StrictHostKeyChecking=no ${base_dir}/* ${machine_ip}:${app_dir}/

fleetctl start ${serv_inst}

echo "Docker registry instance(${serv_inst}) had deployed on server ${machine_ip}"
echo "You can manage the registry service using fleetctl from mow on."
echo "You mush bind your domain(${domain}) to server(${machine_ip}) to use the registry"
