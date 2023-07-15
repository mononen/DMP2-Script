#!/bin/bash

PIA_USERNAME=<PIA Username>
PIA_PASSWORD=<PIA Password>

PIA_REGION_ARRAY=("US California" "US East" "US Midwest" "US Chicago" "US Texas" "US Florida" "US Seattle" "US West" "US Silicon Valley" "US New York City" "US Atlanta" "UK London" "UK Southampton" "UK Manchester" "CA Toronto" "CA Montreal" "CA Vancouver" "AU Sydney" "AU Melbourne" " New Zealand" "Netherlands" "Sweden" "Norway" "Denmark" "Finland" "Switzerland" "France" "Germany" "Belgium" "Austria" "Czech Republic" "Ireland" "Italy" "Spain" "Romania" "Turkey" "South Korea" "Hong Kong" "Singapore" "Japan" "Israel" "Mexico" "Brazil" "India")
PIA_REGION_ARRAY_LAST_INDEX=43

DOCKER_CONTAINER_NAME=DMP2-Container
DOCKER_CONTAINER_IMAGE=act28/pia-openvpn-proxy

TIMESTAMP=$(date "+%Y-%m-%d::%H:%M:%S")

BASH_SCRIPT_RUN_LOGS=DMP2-Script.log
DOCKER_CONTAINER_NETWORK_IO_RX_VALUE_FILE=NetIO.tmp

DOCKER_CONTAINER_CHECK=$(docker ps -a | grep "$DOCKER_CONTAINER_NAME" | wc -l)
if [[ $DOCKER_CONTAINER_CHECK -eq 0 ]]; then
  NEW_DOCKER_CONTAINER=$(docker run -d --cap-add=NET_ADMIN --device=/dev/net/tun --name=$DOCKER_CONTAINER_NAME --dns=209.222.18.218 --dns=8.8.8.8 --restart=always -e "REGION=${PIA_REGION_ARRAY[0]}" -e "USERNAME=$PIA_USERNAME" -e "PASSWORD=$PIA_PASSWORD" -e "LOCAL_NETWORK=10.0.0.0/24" -v /etc/localtime:/etc/localtime:ro -p 8118:8118 $DOCKER_CONTAINER_IMAGE)
  echo $TIMESTAMP: New docker container created with id: $NEW_DOCKER_CONTAINER >> $BASH_SCRIPT_RUN_LOGS

else
  DOCKER_CONTAINER_NETWORK_IO_RX_AND_TX=$(docker stats --no-stream --format "{{.NetIO}}" $DOCKER_CONTAINER_NAME)

  DOCKER_CONTAINER_NETWORK_IO_RX_UNFORMATED=${DOCKER_CONTAINER_NETWORK_IO_RX_AND_TX%/*}
  DOCKER_CONTAINER_NETWORK_IO_RX_FORMATED=${DOCKER_CONTAINER_NETWORK_IO_RX_UNFORMATED%"${DOCKER_CONTAINER_NETWORK_IO_RX_UNFORMATED##*[![:space:]]}"}

  if [ -e $DOCKER_CONTAINER_NETWORK_IO_RX_VALUE_FILE ]; then
    DOCKER_CONTAINER_NETWORK_IO_RX_VALUE=$(cat $DOCKER_CONTAINER_NETWORK_IO_RX_VALUE_FIL)
    echo $DOCKER_CONTAINER_NETWORK_IO_RX_FORMATED > $DOCKER_CONTAINER_NETWORK_IO_RX_VALUE_FILE

    if [[ $DOCKER_CONTAINER_NETWORK_IO_RX_VALUE = $DOCKER_CONTAINER_NETWORK_IO_RX_FORMATED ]] && [[ $DOCKER_CONTAINER_NETWORK_IO_RX_VALUE != *kB* ]]; then
      PIA_REGION_UNFORMATED=$(docker inspect --format '{{ index (index .Config.Env) 1 }}' $DOCKER_CONTAINER_NAME)
      PIA_REGION_FORMATED={PIA_REGION_UNFORMATED#*=}

      for i in "${!PIA_REGION_ARRAY[@]}"; do
        if [[ "${PIA_REGION_ARRAY[$i]}" = "${PIA_REGION_FORMATED}" ]]; then
          PIA_REGION_ARRAY_INDEX=${i};

        fi
      done

      if [[ PIA_REGION_ARRAY_INDEX -lt PIA_REGION_ARRAY_LAST_INDEX ]]; then
        NEW_PIA_REGION=${PIA_REGION_ARRAY[$((PIA_REGION_ARRAY_INDEX + 1))]}

      else
        NEW_PIA_REGION=${PIA_REGION_ARRAY[0]}

      fi

        DOCKER_CONTAINER_LOGS=$(docker logs $DOCKER_CONTAINER_NAME)
        echo $DOCKER_CONTAINER_LOGS > DMP2-Container($TIMESTAMP).log

        STOP_DOCKER_CONTAINER=$(docker stop $DOCKER_CONTAINER_NAME)
        echo $TIMESTAMP: Docker container $STOP_DOCKER_CONTAINER stopped >> $BASH_SCRIPT_RUN_LOGS

        REMOVE_DOCKER_CONTAINER=$(docker rm $DOCKER_CONTAINER_NAME)
        echo $TIMESTAMP: Docker container $REMOVE_DOCKER_CONTAINER removed >> $BASH_SCRIPT_RUN_LOGS

        NEW_DOCKER_CONTAINER=$(docker run -d --cap-add=NET_ADMIN --device=/dev/net/tun --name=$DOCKER_CONTAINER_NAME --dns=209.222.18.218 --dns=209.222.18.222 --restart=always -e "REGION=$NEW_PIA_REGION" -e "USERNAME=$PIA_USERNAME" -e "PASSWORD=$PIA_PASSWORD" -e "LOCAL_NETWORK=10.0.0.0/24" -v /etc/localtime:/etc/localtime:ro -p 8118:8118 $DOCKER_CONTAINER_IMAGE)
        echo $TIMESTAMP: New docker container created with id: $NEW_DOCKER_CONTAINER >> $BASH_SCRIPT_RUN_LOGS

      fi

  else
    echo $DOCKER_CONTAINER_NETWORK_IO_RX_FORMATED > $DOCKER_CONTAINER_NETWORK_IO_RX_VALUE_FILE

  fi

fi
