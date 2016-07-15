#!/bin/bash
# Create by Jin Xiaoyuan at 2016-07-13 14:36

if [[ x$1 == "x" ]]; then
    echo "Notice: domain_or_ip not specified, using default: pool.docker.gzts.com"
    sleep 2
fi

CN_CA="GZTS CA ROOT by Jinxiaoyuan"
CN_CERT="${1:-pool.docker.gzts.com}"


DIR_OUT="./certs"
mkdir -p ${DIR_OUT}


######### Create Root CA ##############
function gen_ca(){
    if [[ x$1 == "x" ]]; then
        echo "Usage: gen_ca COMMON_NAME"
        return 1
    fi
    openssl genrsa -out ${DIR_OUT}/ca-key.pem 2048
    echo "CA KEY saved as: ${DIR_OUT}/ca-key.pem"
    openssl req -x509 -new -sha256 -nodes -key ${DIR_OUT}/ca-key.pem -days 10000 -out ${DIR_OUT}/ca.crt -subj "/CN=$1"
    echo "CA certificate saved as: ${DIR_OUT}/ca.pem"
}

####### OPENSSL Keypair ##############
function gen_keypair(){
    if [[ x$1 == "x" ]]; then
        echo "Usage: gen_ca COMMON_NAME [CA_PATH] [CAKEY_PATH]"
        return 1
    fi
    com_name=$1
    if [[ x$2 == "x" || ! -s $2 || x$3 == "x" || ! -s $3 ]]; then
        ca_key="${DIR_OUT}/ca-key.pem"
        ca_file="${DIR_OUT}/ca.crt"
        if ! [[ -s ${ca_key} && -s ${ca_file} ]]; then
            read -p "No valid CA keypair specified, generate a new CA keypair now?(y/n): " ans
            if [[ x${ans} == "xy" ]]; then
                gen_ca "${CN_CA}"
            else
                echo "Cancel gen_keypair"
                return 0
            fi
        fi
    fi

    # create a config file
    SSLCNF="${RANDOM}_ssl.conf"
cat <<EOF > ${SSLCNF}
[req]
prompt = no
default_bits        = 2048
encrypt_key         = no
default_md          = sha256
distinguished_name  = req_distinguished_name
req_extensions      = v3_req
[ req_distinguished_name ]
stateOrProvinceName = Guangdong
countryName = CN
commonName = ${com_name}
emailAddress = shonnchin@gmail.com
organizationName = GZTS
[ v3_req ]
keyUsage=nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${com_name}
EOF
# DNS.2 = your_domain2
# DNS.3 = your_domain3
# IP.1 = your_ip1
# IP.2 = your_ip2
# EOF

    # Generate Keypair
    openssl genrsa -out ${DIR_OUT}/${com_name}-key.pem 2048
    openssl req -new -sha256 -key ${DIR_OUT}/${com_name}-key.pem -out ${DIR_OUT}/${com_name}.csr -config ${SSLCNF}
    openssl x509 -req -sha256 -in ${DIR_OUT}/${com_name}.csr -CA ${ca_file} -CAkey ${ca_key} -CAcreateserial -out ${DIR_OUT}/${com_name}.crt -days 3650 -extensions v3_req -extfile ${SSLCNF}
    rm -f ${SSLCNF}
}

gen_keypair "${CN_CERT}"
echo "All certificates were generated to ${DIR_OUT} "
ls -l ${DIR_OUT}

