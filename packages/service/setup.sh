#!/bin/bash

DB_CONTAINER_NAME="fpt-db"
POSTGRES_USER="fpt-user"
POSTGRES_PASSWORD="password"
POSTGRES_DB="fpt-db"
POSTGRES_PORT="5432"

# Verifica se o container já existe
if [ "$(docker ps -a -q -f name=^/${DB_CONTAINER_NAME}$)" ]; then
    echo "Container $DB_CONTAINER_NAME já existe."
    # Verifica se está rodando
    if [ "$(docker ps -q -f name=^/${DB_CONTAINER_NAME}$)" ]; then
        echo "Container $DB_CONTAINER_NAME já está rodando."
    else
        echo "Iniciando o container $DB_CONTAINER_NAME..."
        docker start $DB_CONTAINER_NAME
    fi
else
    echo "Criando e subindo o container $DB_CONTAINER_NAME..."
    docker run -d \
        --name $DB_CONTAINER_NAME \
        -e POSTGRES_USER=$POSTGRES_USER \
        -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
        -e POSTGRES_DB=$POSTGRES_DB \
        -p $POSTGRES_PORT:5432 \
        postgres:15
fi

echo "Banco de dados disponível em: postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:$POSTGRES_PORT/$POSTGRES_DB" 