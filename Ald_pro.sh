if [ "$EUID" -ne 0 ]
  then echo "Use sudo, dummy."
  exit
fi
ALD_Pro  () {
  # переменные хоста
  read -p 'Введите имя этого ПК: ' -i $(hostname -s) -e PC_NAME
  read -p 'Введите имя домена: ' -i $(hostname -d) -e DOMAIN
    
  #Меняем имя хоста
  hostnamectl set-hostname "$PC_NAME.$DOMAIN"
  # переменные сети
  read -p 'Введите имя интерфейса: ' -i eth0 -e INTERFACE
  read -p 'Введите имя интерфейса: ' -i eth1 -e INTER
  read -p 'Введите адрес этого ПК: ' -i $(hostname -i) -e IP
  read -p 'Введите маску подсети: ' -i 24 -e SUBNET
    
  # удаляем все соединения
  rm /etc/network/interfaces.d/* 2> /dev/null
  nmcli --terse connection show 2> /dev/null | cut -d : -f 1 | \
  while read name; do echo nmcli connection delete "$name" 2> /dev/null; done
    
  # Выключаем NetworkManager
  systemctl disable --now NetworkManager
  systemctl mask NetworkManager

  # Настройка сети
  echo "auto $INTERFACE" > "/etc/network/interfaces.d/$INTERFACE"
  echo "iface $INTERFACE inet static" >> "/etc/network/interfaces.d/$INTERFACE"
  echo -e "\taddress $IP" >> "/etc/network/interfaces.d/$INTERFACE"
  echo -e "\tnetmask $SUBNET" >> "/etc/network/interfaces.d/$INTERFACE"
  echo -e "\tdns-nameserver 127.0.0.1" >> "/etc/network/interfaces.d/$INTERFACE"
  echo -e "\tdns-search $DOMAIN" >> "/etc/network/interfaces.d/$INTERFACE"
  echo "auto $INTER" > "/etc/network/interfaces.d/$INTER"
  echo "iface $INTER inet dhcp" >> "/etc/network/interfaces.d/$INTER"
  echo "127.0.0.1 localhost.localdomain localhost" > /etc/hosts
  echo "127.0.1.1 $PC_NAME" >> /etc/hosts
  echo "$IP $PC_NAME.$DOMAIN $PC_NAME" >> /etc/hosts
  systemctl restart networking
  echo "deb https://download.astralinux.ru/aldpro/stable/repository-main/ 1.0.0 main" > /etc/apt/sources.list.d/aldpro.list
  echo "deb https://download.astralinux.ru/aldpro/stable/repository-extended/ generic main" >> /etc/apt/sources.list.d/aldpro.list
  echo "deb http://download.astralinux.ru/astra/frozen/1.7_x86-64/1.7.1/repository-base 1.7_x86-64 main non-free contrib" > /etc/apt/sources.list
  echo "deb http://download.astralinux.ru/astra/frozen/1.7_x86-64/1.7.1/repository-extended 1.7_x86-64 main contrib non-free" >> /etc/apt/sources.list
  echo "Package: *" > /etc/apt/preferences.d/aldpro
  echo "Pin: release n=generic" >> /etc/apt/preferences.d/aldpro
  echo "Pin-Priority: 900" >> /etc/apt/preferences.d/aldpro
  apt update && apt upgrade -y
  DEBIAN_FRONTEND=noninteractive apt-get install -q -y aldpro-mp && reboot
}

Pro_Install () {
  read -p 'Введите имя этого ПК: ' -i $(hostname -s) -e PC_NAME
  read -p 'Введите имя домена: ' -i $(hostname -d) -e DOMAIN
  read -p 'Введите адрес этого ПК: ' -i $(hostname -i) -e IP
  read -p 'Введите пароль администратора домена ' -i xxXX1234 -e ADMIN_PASSWORD
  /opt/rbta/aldpro/mp/bin/aldpro-server-install.sh -d $DOMAIN -n $PC_NAME -p $ADMIN_PASSWORD --ip $IP --no-reboot
  reboot
}

echo "ALD_Pro [1]"
echo "Pro_Install [2]"
read -p 'ALD_Pro [0124] ' WHICH_FUNC

if grep -q "1" <<< "$WHICH_FUNC"; then
  ALD_Pro
fi
if grep -q "2" <<< "$WHICH_FUNC"; then
  Pro_Install
fi
