FROM daocloud.io/centos:6.6

MAINTAINER Jin Xiaoyuan <shonnchin@gmail.com>

RUN yum groupinstall -y 'Development tools' && \
yum install -y readline readline-devel readline-static \
openssl openssl-devel openssl-static sqlite-devel \
memcached libmemcached-devel libmemcached \
libffi-devel libffi \
bzip2-devel bzip2-libs \
tar git vim-enhanced && \
yum clean all

RUN mkdir -p /data/apps/.pyenv && \
git clone git://github.com/yyuu/pyenv.git /data/apps/.pyenv && \
git clone git://github.com/yyuu/pyenv-virtualenv.git /data/apps/.pyenv/plugins/pyenv-virtualenv

WORKDIR /data/apps
RUN echo -e '\n\
export PYTHON_BUILD_MIRROR_URL=http://pyenv.qiniudn.com/pythons/\n\
export PYENV_ROOT="/data/apps/.pyenv"\n\
if [ -d "${PYENV_ROOT}" ]; then\n\
    export PATH="${PYENV_ROOT}/bin:${PATH}"\n\
    eval "$(pyenv init -)"\n\
    eval "$(pyenv virtualenv-init -)"\n\
fi\n' >> ~/.bashrc && \
source ~/.bashrc && pyenv install 2.7.11 && pyenv global 2.7.11 && mkdir -p ~/.pip && \
echo -e '[global]\nindex-url = https://pypi.mirrors.ustc.edu.cn/simple' >> ~/.pip/pip.conf && pip install -U pip 
#&& pip install -r requirements.txt && \
#pip install 'git+git://github.com/dlrust/python-memcached-stats.git'

#EXPOSE 80
CMD ["/bin/bash"]
