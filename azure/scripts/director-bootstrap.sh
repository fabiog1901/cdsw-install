#!/bin/bash
set -o errexit

echo "Create log directory"
./scripts/create-log-dir.sh

echo "Installing KDC"
./scripts/install-mit-kdc.sh

echo "Installing Java"
./scripts/java8-bootstrap-script.sh

echo "Installing Director"
# ./scripts/install-director.sh

echo "Adding Kerberos principals"
./scripts/kerberos-addprinc.sh

echo "Deploying the Cluster"
./scripts/create-deployment.sh

# Terraform can inadvertently kill the last command if it exits immediately. So let's wait a few seconds...
sleep 30
