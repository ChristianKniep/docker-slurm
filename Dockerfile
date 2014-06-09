###### Slurmctld images
# A docker image that provides a slurmctld
FROM qnib/terminal
MAINTAINER "Christian Kniep <christian@qnib.org>"

##### USER
# Set (very simple) password for root
RUN echo "root:root"|chpasswd
ADD root/ssh /root/.ssh
RUN chmod 600 /root/.ssh/authorized_keys
RUN chown -R root:root /root/*

# cluser
RUN mkdir -p /chome
RUN useradd -u 2000 -d /chome/cluser -m cluser
RUN echo "cluser:cluser"|chpasswd
ADD cluser/.ssh /chome/cluser/.ssh
RUN chmod 600 /chome/cluser/.ssh/authorized_keys
RUN chmod 600 /chome/cluser/.ssh/id_rsa
RUN chmod 644 /chome/cluser/.ssh/id_rsa.pub

RUN chown cluser -R /chome/cluser
# munge
RUN yum install -y munge
RUN chown root:root /var/lib/munge/
RUN chown root:root /var/log/munge/
RUN chown root:root /run/munge/
RUN chown root:root /etc/munge/
ADD etc/munge/munge.key /etc/munge/munge.key
RUN chmod 600 /etc/munge/munge.key
RUN chown root:root /etc/munge/munge.key
ADD etc/supervisord.d/munge.ini /etc/supervisord.d/

### SSHD
RUN yum install -y openssh-server
RUN mkdir -p /var/run/sshd
RUN sshd-keygen
RUN sed -i -e 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
ADD etc/supervisord.d/sshd.ini /etc/supervisord.d/sshd.ini

# We do not care about the known_hosts-file
RUN echo "        StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "        UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
RUN echo "        AddressFamily inet" >> /etc/ssh/ssh_config

# misc
RUN yum install -y bind-utils

# slurm
ADD yum-cache/slurm /tmp/yum-cache/slurm
RUN yum install -y /tmp/yum-cache/slurm/slurm-2.6.7-1.x86_64.rpm
RUN mkdir -p /usr/local/etc/
RUN touch /usr/local/etc/slurm.conf
RUN rm -rf /tmp/yum-cache/slurm
RUN useradd -u 2001 -d /chome/slurm -M slurm

## confd
# bc needed within /root/bin/confd_update_slurm.sh
RUN yum install -y bc
ADD usr/local/bin/confd /usr/local/bin/confd
ADD etc/confd/conf.d/slurm.conf.toml /etc/confd/conf.d/slurm.conf.toml
ADD etc/confd/templates/slurm.conf.tmpl /etc/confd/templates/slurm.conf.tmpl
ADD root/bin/confd_update_slurm.py /root/bin/confd_update_slurm.py



CMD /bin/supervisord -c /etc/supervisord.conf