#!/bin/bash

# README FIRST
# This script is intended to be run on a fresh install of Ubuntu and has been tested on Ubuntu 22.04.1 LTS
# It will install MAAS from the edge channel, restore a database dump from the maas-ui-testing repo and add a test admin user

# install snapd and make sure it's enabled
sudo apt update
sudo apt install snapd
sudo systemctl enable snapd

sudo snap install maas-test-db --channel=latest/edge
sudo snap install maas --channel=latest/edge
wget -O maasdb.dump https://github.com/canonical/maas-ui-testing/raw/main/db/maasdb-22.04-master-1000.dump
sudo sed -i "s/dynamic_shared_memory_type = posix/dynamic_shared_memory_type = sysv/" /var/snap/maas-test-db/common/postgres/data/postgresql.conf
sudo snap restart maas-test-db
sudo mv maasdb.dump /var/snap/maas-test-db/common/maasdb.dump
sudo snap run --shell maas-test-db.psql -c 'db-dump restore /var/snap/maas-test-db/common/maasdb.dump maassampledata'
export INTERFACE=$(ip route | grep default | cut -d ' ' -f 5)
export IP_ADDRESS=$(ip -4 addr show dev $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
sudo maas init region+rack --database-uri maas-test-db:/// --maas-url http://${IP_ADDRESS}:5240/MAAS
sudo sed -i "s/database_name: maasdb/database_name: maassampledata/" /var/snap/maas/current/regiond.conf
sudo snap restart maas
sudo maas createadmin --username=admin --password=test --email=fake@example.org
