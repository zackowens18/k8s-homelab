#!/bin/sh

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Attempting to deploy talos nodes"

node_to_ip = sed -e 's/:[^:\/\/]/="/g;s/$/"/g;s/ *=/=/g' "$SCRIPT_DIR/../cluster-setup/template/nodes_to_ip.yaml"

# TO DO finish