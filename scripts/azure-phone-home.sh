#!/bin/bash
set -euo pipefail

# =============================================================================
# Nuon Azure Phone-Home Script
#
# Use this script when you manually created the Azure resources from the Nuon
# ARM template instead of deploying it directly.
#
# Two modes:
#   outputs     — Query Azure and print the phone-home JSON payload to stdout
#                 (all status output goes to stderr so you can pipe/copy easily)
#   phone-home  — Query Azure and POST the payload to Nuon's phone-home endpoint
#
# Prerequisites: az CLI (logged in), curl, jq
#
# Usage:
#   ./azure-phone-home.sh outputs    <install-id> <resource-group-name>
#   ./azure-phone-home.sh phone-home <install-id> <phone-home-id> <resource-group-name>
# =============================================================================

usage() {
  cat >&2 <<EOF
Usage:
  $0 outputs    <install-id> <resource-group-name>
  $0 phone-home <install-id> <phone-home-id> <resource-group-name>

Commands:
  outputs      Query Azure resources and print the phone-home JSON to stdout.
  phone-home   Query Azure resources and POST the payload to Nuon.

Arguments:
  install-id           The Nuon Install ID (e.g. inllolrxslk50vfqbuhdzlpgi9)
  phone-home-id        The phone-home ID from the install stack (e.g. awsvo7dk9koh0gkyey0un4m1j8)
  resource-group-name  The Azure resource group containing the Nuon resources.
EOF
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

MODE="$1"
shift

case "$MODE" in
  outputs)
    if [ $# -lt 2 ]; then usage; fi
    INSTALL_ID="$1"
    RESOURCE_GROUP_NAME="$2"
    ;;
  phone-home)
    if [ $# -lt 3 ]; then usage; fi
    INSTALL_ID="$1"
    PHONE_HOME_ID="$2"
    RESOURCE_GROUP_NAME="$3"
    PHONE_HOME_URL="https://api.nuon.co/v1/installs/${INSTALL_ID}/phone-home/${PHONE_HOME_ID}"
    ;;
  *)
    echo "ERROR: Unknown command '${MODE}'" >&2
    usage
    ;;
esac

VNET_NAME="${INSTALL_ID}-vnet"
KEY_VAULT_NAME="${INSTALL_ID:0:24}"

PUBLIC_SUBNET_NAMES=(
  "${INSTALL_ID}-public-subnet-zone1"
  "${INSTALL_ID}-public-subnet-zone2"
  "${INSTALL_ID}-public-subnet-zone3"
)

PRIVATE_SUBNET_NAMES=(
  "${INSTALL_ID}-private-subnet-zone1"
  "${INSTALL_ID}-private-subnet-zone2"
  "${INSTALL_ID}-private-subnet-zone3"
)

# --- Preflight checks --------------------------------------------------------

for cmd in az curl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' is required but not found in PATH." >&2
    exit 1
  fi
done

echo "Querying Azure for resource details in resource group: ${RESOURCE_GROUP_NAME}" >&2

# --- Gather subscription & resource group info -------------------------------

SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
SUBSCRIPTION_TENANT_ID=$(az account show --query "tenantId" -o tsv)

RG_INFO=$(az group show --name "${RESOURCE_GROUP_NAME}" -o json)
RESOURCE_GROUP_ID=$(echo "$RG_INFO" | jq -r '.id')
RESOURCE_GROUP_LOCATION=$(echo "$RG_INFO" | jq -r '.location')

echo "  Subscription:    ${SUBSCRIPTION_ID}" >&2
echo "  Tenant:          ${SUBSCRIPTION_TENANT_ID}" >&2
echo "  Resource Group:  ${RESOURCE_GROUP_NAME} (${RESOURCE_GROUP_LOCATION})" >&2

# --- Gather VNet info --------------------------------------------------------

VNET_INFO=$(az network vnet show \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${VNET_NAME}" \
  -o json)

VNET_ID=$(echo "$VNET_INFO" | jq -r '.id')
echo "  VNet:            ${VNET_NAME}" >&2

# --- Gather Key Vault info ---------------------------------------------------

KEY_VAULT_ID=$(az keyvault show \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${KEY_VAULT_NAME}" \
  --query "id" -o tsv 2>/dev/null || echo "")

if [ -z "$KEY_VAULT_ID" ]; then
  echo "  Key Vault:       (not found — will send empty)" >&2
  KEY_VAULT_ID=""
  KEY_VAULT_NAME=""
else
  echo "  Key Vault:       ${KEY_VAULT_NAME}" >&2
fi

# --- Gather subnet info ------------------------------------------------------

collect_subnets() {
  local -n names_arr=$1
  local ids_csv=""
  local names_csv=""

  for subnet_name in "${names_arr[@]}"; do
    subnet_id=$(az network vnet subnet show \
      --resource-group "${RESOURCE_GROUP_NAME}" \
      --vnet-name "${VNET_NAME}" \
      --name "${subnet_name}" \
      --query "id" -o tsv 2>/dev/null || echo "")

    if [ -n "$subnet_id" ]; then
      if [ -n "$ids_csv" ]; then
        ids_csv="${ids_csv},${subnet_id}"
        names_csv="${names_csv},${subnet_name}"
      else
        ids_csv="${subnet_id}"
        names_csv="${subnet_name}"
      fi
    fi
  done

  echo "${ids_csv}|${names_csv}"
}

PUBLIC_RESULT=$(collect_subnets PUBLIC_SUBNET_NAMES)
PUBLIC_SUBNET_IDS_CSV="${PUBLIC_RESULT%%|*}"
PUBLIC_SUBNET_NAMES_CSV="${PUBLIC_RESULT##*|}"

PRIVATE_RESULT=$(collect_subnets PRIVATE_SUBNET_NAMES)
PRIVATE_SUBNET_IDS_CSV="${PRIVATE_RESULT%%|*}"
PRIVATE_SUBNET_NAMES_CSV="${PRIVATE_RESULT##*|}"

echo "  Public subnets:  ${PUBLIC_SUBNET_NAMES_CSV}" >&2
echo "  Private subnets: ${PRIVATE_SUBNET_NAMES_CSV}" >&2

# --- Build payload -----------------------------------------------------------

PAYLOAD=$(cat <<EOF
{
  "request_type": "Create",
  "phone_home_type": "azure",
  "resource_group_id": "${RESOURCE_GROUP_ID}",
  "resource_group_name": "${RESOURCE_GROUP_NAME}",
  "resource_group_location": "${RESOURCE_GROUP_LOCATION}",
  "network_id": "${VNET_ID}",
  "network_name": "${VNET_NAME}",
  "key_vault_id": "${KEY_VAULT_ID}",
  "key_vault_name": "${KEY_VAULT_NAME}",
  "public_subnet_ids": "${PUBLIC_SUBNET_IDS_CSV}",
  "public_subnet_names": "${PUBLIC_SUBNET_NAMES_CSV}",
  "private_subnet_ids": "${PRIVATE_SUBNET_IDS_CSV}",
  "private_subnet_names": "${PRIVATE_SUBNET_NAMES_CSV}",
  "subscription_id": "${SUBSCRIPTION_ID}",
  "subscription_tenant_id": "${SUBSCRIPTION_TENANT_ID}"
}
EOF
)

# --- Execute mode ------------------------------------------------------------

if [ "$MODE" = "outputs" ]; then
  echo "$PAYLOAD" | jq .
  exit 0
fi

# phone-home mode
echo "" >&2
echo "Sending phone-home to: ${PHONE_HOME_URL}" >&2

HTTP_CODE=$(curl -X POST \
  "${PHONE_HOME_URL}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$PAYLOAD" \
  --fail \
  --silent \
  --show-error \
  -w "\n%{http_code}" \
  -o /dev/stderr 2>&1 | tail -1)

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
  echo "Phone home sent successfully (HTTP ${HTTP_CODE})." >&2
else
  echo "ERROR: Phone home failed with HTTP ${HTTP_CODE}." >&2
  exit 1
fi
