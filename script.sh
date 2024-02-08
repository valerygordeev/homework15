#!/bin/bash

sudo su
cd
sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd.service
useradd otusadm && useradd otus
echo "Otus2022!" | sudo passwd --stdin otusadm && echo "Otus2022!" | sudo passwd --stdin otus
groupadd -f admin
usermod otusadm -a -G admin && usermod root -a -G admin && usermod vagrant -a -G admin
cat /etc/group | grep admin
cat > /usr/local/bin/login.sh << 'EOL'
#!/bin/bash
if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
  if getent group admin | grep -qw "$PAM_USER"; then
    exit 1
  else
    exit 0
  fi
else
  exit 0
fi
EOL
chmod +x /usr/local/bin/login.sh
sed -i '4i\auth       required     pam_exec.so /usr/local/bin/login.sh' /etc/pam.d/sshd
cat /etc/pam.d/sshd
systemctl stop vboxadd-service.service

