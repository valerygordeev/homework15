##homework15
#PAM
```
1. Загружаем систему "generic/centos8s"  версии 4.3.12 в ВМ с помощью vagrant
2. Подключаемся к созданной ВМ: 
     vagrant ssh
3. Переходим в root-пользователя: 
     sudo su
4. Создаём пользователя otusadm и otus: 
     useradd otusadm && sudo useradd otus
4. Назначаем пароли для созданных пользователей:
     echo "Otus2022!" | passwd --stdin otusadm && echo "Otus2022!" | passwd --stdin otus
5. Создаём группу admin: 
     groupadd -f admin
6. Добавляем пользователей vagrant,root и otusadm в группу admin:
     usermod otusadm -a -G admin && usermod root -a -G admin && usermod vagrant -a -G admin
7. Проверяем вхождение пользователей в группу admin:
     [root@pam vagrant]# cat /etc/group | grep admin
     admin:x:1003:otusadm,root,vagrant
8. Проверяем, что они созданные пользователи могут подключаться по SSH к ВМ. Вводим команду на хостовой машины: 
     ssh otus@192.168.57.10
     ssh otusadm@192.168.57.10
9. Создаем файл-скрипт для проверки выходного дня и определения вхождения пользователя в группу admin:
     #!/bin/bash
     #Первое условие: если день недели суббота или воскресенье
     if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
      #Второе условие: входит ли пользователь в группу admin
      if getent group admin | grep -qw "$PAM_USER"; then
             #Если пользователь входит в группу admin, то он может подключиться
             exit 0
           else
             #Иначе ошибка (не сможет подключиться)
             exit 1
         fi
       #Если день не выходной, то подключиться может любой пользователь
       else
         exit 0
     fi
     
     Записываем его в /usr/local/bin/login.sh
10. Назначаем права на исполнение: 
     chmod +x /usr/local/bin/login.sh
11. Указываем в файле /etc/pam.d/sshd модуль pam_exec для запуска внешних команд и наш скрипт:
     [root@pam vagrant]# cat /etc/pam.d/sshd
     #%PAM-1.0
     auth       substack     password-auth
     auth       include      postlogin
     auth       required     pam_exec.so /usr/local/bin/login.sh
     account    required     pam_sepermit.so
     account    required     pam_nologin.so
     account    include      password-auth
     password   include      password-auth
     # pam_selinux.so close should be the first session rule
     session    required     pam_selinux.so close
     session    required     pam_loginuid.so
     # pam_selinux.so open should only be followed by sessions to be executed in the user context
     session    required     pam_selinux.so open env_params
     session    required     pam_namespace.so
     session    optional     pam_keyinit.so force revoke
     session    optional     pam_motd.so
     session    include      password-auth
     session    include      postlogin

12. Останавливаем гостевые дополнения включая синхронизацию времени
     service vboxadd-service stop
13. Подключаемся к ВМ c хостовой машины (для наглядности в другом терминале):
     ssh otus@192.168.57.10
     ssh otusadm@192.168.57.10
    Проверяем подключение и дату
14. Заходим на ВМ по vagrant ssh и меняем дату на выходной день, например 4 февраля 2024 - воскресенье.
     date 020412302024.00
15. Повторяем п.13. Но теперь удается войти на ВМ только пользователю otus, т.к. пользователь otusadm входит в группу admin, а пользователям группы admin запрещено входить на ВМ по выходным дням согласно скрипту login.sh.
16. Проверяем, что запрет на вход осуществляется модулем PAM auth:
     tail /var/log/secure
     
     [root@pam vagrant]# tail -n 30 /var/log/secure
     Feb  8 06:07:26 pam sshd[4645]: pam_unix(sshd:session): session closed for user otus
     Feb  8 06:07:36 pam systemd[4657]: pam_unix(systemd-user:session): session closed for user otus
     Feb  8 06:07:38 pam sshd[4698]: Accepted password for otusadm from 192.168.57.1 port 39072 ssh2
     Feb  8 06:07:38 pam systemd[4715]: pam_unix(systemd-user:session): session opened for user otusadm by (uid=0)
     Feb  8 06:07:38 pam sshd[4698]: pam_unix(sshd:session): session opened for user otusadm by (uid=0)
     Feb  8 06:08:07 pam sshd[4724]: Received disconnect from 192.168.57.1 port 39072:11: disconnected by user
     Feb  8 06:08:07 pam sshd[4724]: Disconnected from user otusadm 192.168.57.1 port 39072
     Feb  8 06:08:07 pam sshd[4698]: pam_unix(sshd:session): session closed for user otusadm
     Feb  8 06:08:17 pam systemd[4718]: pam_unix(systemd-user:session): session closed for user otusadm
     Feb  8 06:08:19 pam sshd[4767]: Accepted publickey for vagrant from 10.0.2.2 port 47290 ssh2: ED25519 SHA256:WQgYPRjsJrsesN9pyAM1zxXgI+JcYMKR1bZRMw7GSh4
     Feb  8 06:08:19 pam systemd[4772]: pam_unix(systemd-user:session): session opened for user vagrant by (uid=0)
     Feb  8 06:08:19 pam sshd[4767]: pam_unix(sshd:session): session opened for user vagrant by (uid=0)
     Feb  8 06:08:31 pam sudo[4814]: vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/su
     Feb  8 06:08:31 pam sudo[4814]: pam_unix(sudo:session): session opened for user root by vagrant(uid=0)
     Feb  8 06:08:31 pam su[4816]: pam_unix(su:session): session opened for user root by vagrant(uid=0)
     Feb  4 12:30:21 pam unix_chkpwd[4853]: account otus has password changed in future
     Feb  4 12:30:21 pam sshd[4845]: Accepted password for otus from 192.168.57.1 port 32952 ssh2
     Feb  4 12:30:21 pam unix_chkpwd[4859]: account otus has password changed in future
     Feb  4 12:30:21 pam systemd[4857]: pam_unix(systemd-user:session): session opened for user otus by (uid=0)
     Feb  4 12:30:21 pam sshd[4845]: pam_unix(sshd:session): session opened for user otus by (uid=0)
     Feb  4 12:30:29 pam sshd[4866]: Received disconnect from 192.168.57.1 port 32952:11: disconnected by user
     Feb  4 12:30:29 pam sshd[4866]: Disconnected from user otus 192.168.57.1 port 32952
     Feb  4 12:30:29 pam sshd[4845]: pam_unix(sshd:session): session closed for user otus
     Feb  4 12:30:44 pam sshd[4901]: pam_exec(sshd:auth): /usr/local/bin/login.sh failed: exit code 1
     Feb  4 12:30:46 pam sshd[4901]: Failed password for otusadm from 192.168.57.1 port 35806 ssh2
     Feb  4 12:31:00 pam sshd[4901]: pam_exec(sshd:auth): /usr/local/bin/login.sh failed: exit code 1
     Feb  4 12:31:01 pam sshd[4901]: Failed password for otusadm from 192.168.57.1 port 35806 ssh2
     Feb  4 12:31:15 pam sshd[4901]: pam_exec(sshd:auth): /usr/local/bin/login.sh failed: exit code 1
     Feb  4 12:31:17 pam sshd[4901]: Failed password for otusadm from 192.168.57.1 port 35806 ssh2
     Feb  4 12:31:18 pam sshd[4901]: Connection closed by authenticating user otusadm 192.168.57.1 port 35806 [preauth]
```
