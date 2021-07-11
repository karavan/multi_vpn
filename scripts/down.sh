#!/usr/bin/env bash

# Скрипт чистит мусор после остановки канала ProtonVPN.
# Этот скрипт является дополнением к скрипту инициализации сервера VPN
# https://github.com/hwdsl2/setup-ipsec-vpn
#

# Задаем переменные скрипта.
# Объявление $PATH обязательно, если скрипт в процессе работы ругается на ненайденные команды.
#
export PATH="/run/wrappers/bin:/root/.nix-profile/bin:/etc/profiles/per-user/root/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
SED="$(which sed)"
IPtables="$(which iptables)"
IProute2="$(which ip)"

# Читаем из лога инициализации параметры
#
ProtonIF=$1
LOG_UP="/var/log/openvpn/${ProtonIF}.up"
ProtonIP=`${SED} -nE 's/ProtonIP: +([^ ]+)/\1/p' ${LOG_UP}`
ProtonNet=`${SED} -nE 's/ProtonNet: +([^ ]+)/\1/p' ${LOG_UP}`
ProtonGW=`${SED} -nE 's/ProtonGW: +([^ ]+)/\1/p' ${LOG_UP}`
AddrClients=`${SED} -nE 's/AddrClients: +([^ ]+)/\1/p' ${LOG_UP}`

MARKER="10${ProtonIF##*-}"
ROUTE_TABLE=${ProtonIF}


# Чистим таблицу маршрутизации 'proton' и удаляем правило маркировки клиентских пакетов
#
${IPtables} -t mangle -D PREROUTING -s ${AddrClients} -j MARK --set-mark ${MARKER} || true
${IProute2} route del ${ProtonNet} dev ${ProtonIF} src ${ProtonIP} table ${ROUTE_TABLE} || true
${IProute2} route del default via ${ProtonGW} table ${ROUTE_TABLE} || true
${IProute2} rule del from ${ProtonIP} table ${ROUTE_TABLE} || true
${IProute2} rule del from ${AddrClients} fwmark ${MARKER} table ${ROUTE_TABLE} || true

echo -n > ${LOG_UP}
