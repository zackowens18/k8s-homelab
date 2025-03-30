#!/bin/sh
set -e  # Exit on errors

# Default values
cluster_folder_path=""
cluster_endpoint=""
nodes=""

check_talosctl() {
  if ! command -v talosctl >/dev/null 2>&1; then
    echo "Error: talosctl is not installed. Please install it to proceed."
    exit 1
  else
    echo "talosctl is installed."
  fi
}

check_talosctl

# Function to display usage
usage() {
  echo "Usage: $0 --path <cluster_folder_path> --endpoint <cluster-endpoint> --nodes <Nodes> [--insecure]"
  echo "  -p|--path <cluster_folder_path>      Cluster name (single word)"
  echo "  -e|--endpoint <cluster-endpoint>     Cluster endpoint (HTTPS URL)"
  echo "  -N|--nodes <Nodes>                   Comma-separated list of nodes"
  exit 1
}

# Argument parsing
while [ "$#" -gt 0 ]; do
  case "$1" in
    -p | --path)
      cluster_folder_path="$2"
      shift 2
      ;;
    -e | --endpoint)
      cluster_endpoint="$2"
      shift 2
      ;;
    -N | --nodes)
      nodes="$2"
      shift 2
      ;;
    -h | --help)
      usage
      ;;
    *)
      echo "Error: Unknown option $1"
      usage
      ;;
  esac
done

# Validate required arguments
if [ -z "$cluster_folder_path" ] || [ -z "$cluster_endpoint" ] || [ -z "$nodes" ]; then
  echo "Error: Missing required arguments."
  usage
fi
cluster_folder_path=$(realpath $cluster_folder_path)

# Function to setup Talos
talos_setup() {
  for path in "$cluster_folder_path/patches" "$cluster_folder_path/controlplane.yaml" "$cluster_folder_path/talosconfig"; do
    if [ ! -e "$path" ]; then
      echo "Required files missing. Creating a new cluster..."
      intialize_talos_cluster "$@"
    fi
  done
  # apply patches
  original_path=$pwd
  mycluster=$(basename $cluster_folder_path)
  cd $cluster_folder_path 
  echo "Applying Confg to Nodes: $nodes"
  talosctl machineconfig patch controlplane.yaml --patch @./patches/controlplane-patch.yaml -o controlplane.yaml 
  talosctl apply-config --insecure --nodes $nodes --file ./controlplane.yaml
  sleep 120s
  echo "Bootstrapping Node by endpoint $endpoint_ip"
  talos_path=$(realpath ./talosconfig)

  talosctl config merge ./talosconfig
  talosctl config context $mycluster
  talosctl bootstrap --nodes $nodes --endpoints $endpoint_ip 
  echo "Waiting for $nodes to bootstrap then retrieving kubconfig"
  sleep 120s
  echo "nodes $nodes , $"
  talosctl kubeconfig kubeconfig --nodes $nodes --endpoints $endpoint_ip
  echo "kubeconfig can be found at $(pwd)/kubeconfig"
  cd $original_path
}

# Function to initialize Talos cluster
intialize_talos_cluster() {
  echo "Initializing Talos cluster files..."
  # get template directory
  template_dir=$(find ../ -name "controlplane-patch.yaml" | grep "template" | xargs dirname | xargs dirname)
  template_dir=$(realpath $template_dir)
  mkdir -p $cluster_folder_path
  cp -r $template_dir/. $cluster_folder_path
  cluster_name=$(basename $cluster_folder_path)
  original_path=$pwd
  cd $cluster_folder_path
  talosctl gen config $cluster_name $cluster_endpoint --config-patch @./patches/controlplane-patch.yaml
  cd $original_path
}
# get pure endpoint ip from full https address 
endpoint_ip="${cluster_endpoint#https://}"  # Remove 'https://'
endpoint_ip="${endpoint_ip%%:*}"             # Remove ':port'
talos_setup $cluster_folder_path $cluster_endpoint $nodes $endpoint_ip

exit 0