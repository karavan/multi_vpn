#!/usr/bin/env bash

# Скрипт вычисляет умолчательный маршрут в сети VPN и
# создает необходимые правила для перенаправления
# клиентских пакетов через канал ProtonVPN.
# Этот скрипт является дополнением к скрипту инициализации сервера VPN
# https://github.com/hwdsl2/setup-ipsec-vpn
#

# Задаем переменные скрипта.
# Объявление $PATH обязательно, если скрипт в процессе работы ругается на ненайденные команды.
#
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ProtonIF="$1"
ProtonIP="$4"
ProtonNetMask="$5"
Grep="$(which grep)"
SED="$(which sed)"
TAC="$(which tac)"
Echo="$(which echo)"
IPtables="$(which iptables)"
IProute2="$(which ip)"
IPcalc="$(which ipcalc) -b"
LOG_UP="/var/log/openvpn/"${ProtonIF}".up"
LOG_VPN="/var/log/openvpn/"${ProtonIF}".log"
AddrClients="10.148.13${ProtonIF##*-}.0/24"
MARKER="10${ProtonIF##*-}"
ROUTE_TABLE=${ProtonIF} # Для удобства таблица маршрутизации одноименна сетевому интерфейсу.

# Вычисление шлюза в сети ProtonVPN.
# Файл требуется читать с конца на случай добавления логов вместо перезаписывания.
#
ProtonGW=`${TAC} ${LOG_VPN} | sed -nE '0,/route-gateway/{s/.*route-gateway ([^,]+).*/\1/p}'`

# Вычисление адреса сети.
# Предполагается, что четвертым параметром передается клиентский адрес VPN,
# а пятым параметром адрес сети VPN.
#
ProtonNet=`${IPcalc} ${ProtonIP} ${ProtonNetMask} | sed -nE 's/Network: +([^ ]+)/\1/p'`

# Пишем в лог инициализации параметры канала ProtonVPN.
# Это понадобится для скрипта обслуживающего VPN_down
#
(${Echo} -e "ProtonIF: ${ProtonIF}"; \
${Echo} -e "ProtonIP: ${ProtonIP}"; \
${Echo} -e "ProtonNet: ${ProtonNet}"; \
${Echo} -e "ProtonGW: ${ProtonGW}"; \
${Echo} -e "AddrClients: ${AddrClients}") | column -t >${LOG_UP}

# Предварительно в файле /etc/iproute2/rt_tables.d/proton.conf необходимо создать
# таблицу 'proton-N', которая будет отвечать за маршрутизацию клиентских пакетов.
# Добавляем маршруты и правила в таблицу 'proton-N'.
#
${IPtables} -t mangle -A PREROUTING -s ${AddrClients} -j MARK --set-mark ${MARKER}
${IProute2} route add ${ProtonNet} dev ${ProtonIF} src ${ProtonIP} table ${ROUTE_TABLE}
${IProute2} route add default via ${ProtonGW} table ${ROUTE_TABLE}
${IProute2} rule add from ${ProtonIP} table ${ROUTE_TABLE}
${IProute2} rule add from ${AddrClients} fwmark ${MARKER} table ${ROUTE_TABLE}
