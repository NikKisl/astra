#!/usr/bin/env bash
if [[ $(whoami) == "root" ]]; then
# определение необходимостей
read -p 'Сеть [1] / Репозитории [2] / Домен [3] / Вход [4] ' whichScript

##################################
#        Настройка сети          #
##################################
# проверяем необходимость запуска
if grep -q "1" <<< "$whichScript"; then
# задаём имя соединению
con="Проводное соединение 1"
# назначаем хостнейм
read -p 'Введите хостнейм FQDN: ' hostname
hostnamectl set-hostname "$hostname"
# конфигуриуем соединение
read -p 'Введите IP: ' ip
read -p 'Введите маску: ' mask
read -p 'Введите гетвей: ' gateway
read -p 'Введите DNS(для клиента указываем DNS домен): ' dns
nmcli con mod "$con" ip4 $ip/$mask gw4 $gateway
# настраиваем адресс DNS
nmcli con mod "$con" ipv4.dns "$dns"
# отключаем DHCP, Добавляем loopback строку в IPv6
nmcli con mod "$con" ipv4.method manual
chmod 777 /etc/sysctl.d/999-astra.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 0" >> /etc/sysctl.d/999-astra.conf
chmod 644 /etc/sysctl.d/999-astra.conf
# указываем данные hosts
pcDomain=$(hostname -s)
domain=$(hostname -d)
echo "$ip $hostname $pcDomain" >> /etc/hosts
# перезапускаем соединение
nmcli con down "$con" ; nmcli con up "$con"
fi


##################################
#   Конфигурация репозиториев    #
##################################
# проверяем необходимость запуска
if grep -q "2" <<< "$whichScript"; then
#!/usr/bin/env bash
# CD/DVD-1 [Smolensk-1.6]
mkdir -p /srv/repo/smolensk/main
mount /dev/sr0 /media/cdrom
cp -a /media/cdrom/* /srv/repo/smolensk/main
umount /media/cdrom
# CD/DVD 2 [Devel-Smolensk-1.6]
mkdir -p /srv/repo/smolensk/devel
mount /dev/sr1 /media/cdrom
cp -a /media/cdrom/* /srv/repo/smolensk/devel
umount /media/cdrom
# CD/DVD 3 [20200722SE16]
mkdir -p /srv/repo/smolensk/update
mount /dev/sr2 /media/cdrom
cp -a /media/cdrom/* /srv/repo/smolensk/update
umount /media/cdrom
# CD/DVD 4 [Repository-Update-Devel]
mkdir -p /srv/repo/smolensk/update-dev
mount /dev/sr3 /media/cdrom
cp -a /media/cdrom/* /srv/repo/smolensk/update-dev
umount /media/cdrom
# дополняем источники
echo -n > /etc/apt/sources.list
echo "# репозиторий основного диска" >> /etc/apt/sources.list
echo "deb file:/srv/repo/smolensk/main smolensk main contrib non-free" >> /etc/apt/sources.list
echo "# репозиторий диска со средствами разработки" >> /etc/apt/sources.list
echo "deb file:/srv/repo/smolensk/devel smolensk main contrib non-free" >> /etc/apt/sources.list
echo "# репозиторий диска с обновлением основного диска" >> /etc/apt/sources.list
echo "deb file:/srv/repo/smolensk/update smolensk main contrib non-free" >> /etc/apt/sources.list
echo "# репозиторий диска с обновлением диска со средствами разработки" >> /etc/apt/sources.list
echo "deb file:/srv/repo/smolensk/update-dev smolensk main contrib non-free" >> /etc/apt/sources.list
# обновление пакетов
apt update -y
apt dist-upgrade -y
apt -f install -y
# включение SSH
apt install ssh -y
systemctl enable ssh
systemctl start ssh
# перезагружаем
read -p 'Перезагрузить машину? ' doReboot
if [[ "$doReboot" == "y" ]]; then
    reboot
fi
fi

##################################
#       Установка домена         #
##################################
# проверяем необходимость запуска
if grep -q "3" <<< "$whichScript"; then
echo "dns должен быть loopback и имя сервера должно быть FQDN = astra.demo.lab"
con="Проводное соединение 1"
# добавление репозиториев и установка пакетов для УЦ Dogtag FreeIPA
echo -n > /etc/apt/sources.list
echo "# репозиторий с актуальными стабильными версиями пакетов" >> /etc/apt/sources.list
echo "deb https://download.astralinux.ru/astra/stable/orel/repository orel contrib main non-free" >> /etc/apt/sources.list
echo "# репозиторий с тестируемыми версиями пакетов" >> /etc/apt/sources.list
echo "deb https://download.astralinux.ru/astra/testing/orel/repository orel contrib main non-free" >> /etc/apt/sources.list
echo "# репозиторий с экспериментальными пакетами" >> /etc/apt/sources.list
echo "deb https://download.astralinux.ru/astra/experimental/orel/repository orel contrib main non-free" >> /etc/apt/sources.list

# обновление пакетов
apt update -y
# установка пакетов для УЦ
apt -d install pki-ca pki-kra -y
dpkg -i /var/cache/apt/archives/*.deb

# восстанавливаем репозитории источники
echo -n > /etc/apt/sources.list
echo "# репозиторий основного диска" >> /etc/apt/sources.list
echo "deb file:/srv/repo/smolensk/main smolensk main contrib non-free" >> /etc/apt/sources.list
echo "# репозиторий диска со средствами разработки" >> /etc/apt/sources.list
echo "deb file:/srv/repo/smolensk/devel smolensk main contrib non-free" >> /etc/apt/sources.list
echo "# репозиторий диска с обновлением основного диска" >> /etc/apt/sources.list
echo "deb file:/srv/repo/smolensk/update smolensk main contrib non-free" >> /etc/apt/sources.list
echo "# репозиторий диска с обновлением диска со средствами разработки" >> /etc/apt/sources.list
echo "deb file:/srv/repo/smolensk/update-dev smolensk main contrib non-free" >> /etc/apt/sources.list

# обновление пакетов
apt update -y

#read -p 'Введите хостнейм еще раз: ' hostname
# конфигуриуем соединение
read -p 'Введите DNS такой же как IP: ' dns

# настраиваем адресс DNS
nmcli con mod "$con" ipv4.dns "$dns"

# перезапускаем соединение
nmcli con down "$con" ; nmcli con up "$con"

# установка пакетов FreeIPA
apt install fly-admin-freeipa-server -y
# профилактика битых пакетов
apt -f install -y
# проверяем переменные сети

# конфигурируем данные домена
pcDomain=$(hostname -s)
domain=$(hostname -d)
ip=$(hostname -i)

# конфигурация домена
astra-freeipa-server -d $domain -n $pcDomain -px -ip $ip -o --dogtag -y
read -p 'Перезагрузить машину? ' doReboot
if [[ "$doReboot" == "y" ]]; then
    reboot
fi
fi

##################################
#          Ввод в домен          #
##################################
# проверяем необходимость запуска
if grep -q "4" <<< "$whichScript"; then
# установка пакетов
apt install fly-admin-freeipa-client -y
# профилактика битых пакетов
apt -f install -y
# конфигурируем данные домена
domain=$(hostname -d)
# входим в домен
astra-freeipa-client -d $domain
fi
# перезагружаем
read -p 'Перезагрузить машину? ' doReboot
if [[ "$doReboot" == "y" ]]; then
    reboot
fi
# проверка sudo
else
echo "Запусти скрипт через sudo!"
fi
fi