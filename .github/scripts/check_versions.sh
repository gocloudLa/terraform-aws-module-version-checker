#!/bin/bash

# ------------------------------------------------------------------------------
# 📄 Terraform Registry Module Version Checker
#
# This script analyzes a Terraform project's module usage to identify and report 
# the versions of modules that are sourced from the Terraform Registry (registry.terraform.io).
# It performs the following steps:
# 
# 1. Initializes Terraform without backend to safely fetch module data.
# 2. Runs 'terraform modules' and overwrites modules.plain with current data.
# 3. Extracts all registry module sources and their exact versions from the file.
# 4. For each module, it queries the Terraform Registry API to check if the used
#    version is the latest available.
# 5. Generates a Markdown report indicating which modules are up to date and which are not.
# ------------------------------------------------------------------------------

INPUT_FILE="example/complete/modules.plain"
OUTPUT_FILE="version_report.md"
TMP_FILE=".modules_cleaned.tmp"

# Step 1: Always regenerate modules.plain
echo "🔄 Generating fresh module list from 'terraform modules'..."
terraform init -input=false -backend=false > /dev/null
terraform modules > "$INPUT_FILE"

if [[ $? -ne 0 ]]; then
  echo "❌ Failed to generate $INPUT_FILE using 'terraform modules'. Aborting."
  exit 1
fi

# Step 2: Extract module source and exact version cleanly
sed -nE 's/^.*\[(registry\.terraform\.io[^]]+)\][[:space:]]+([0-9]+\.[0-9]+\.[0-9]+).*$/\1 => \2/p' "$INPUT_FILE" > "$TMP_FILE"

echo ">>> Contents of $TMP_FILE:"
cat "$TMP_FILE"
echo ">>> End contents"

# Step 3: Initialize Markdown report
echo "# 📦 Terraform Module Version Report" > "$OUTPUT_FILE"
echo "_Generated on $(date)_" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Step 4: Check each module version against the latest from Terraform Registry
while IFS="=>" read -r MODULE_PATH USED_VERSION; do
  MODULE_PATH=$(echo "$MODULE_PATH" | xargs)
  USED_VERSION=$(echo "$USED_VERSION" | xargs)
  # Remove any non-numeric prefix like '>' or spaces
  USED_VERSION=$(echo "$USED_VERSION" | sed 's/^[^0-9]*//')

  if [[ -z "$MODULE_PATH" || "$MODULE_PATH" != registry.terraform.io/* ]]; then
    continue
  fi

  # Clean submodules path (remove anything after //modules)
  MODULE_PATH_CLEAN=$(echo "$MODULE_PATH" | sed -E 's,//modules.*,,')
  IFS='/' read -r _ namespace name provider <<< "$MODULE_PATH_CLEAN"

  if [[ -z "$namespace" || -z "$name" || -z "$provider" ]]; then
    echo "⚠️ Skipping malformed entry: $MODULE_PATH" | tee -a "$OUTPUT_FILE"
    continue
  fi

  API_URL="https://registry.terraform.io/v1/modules/${namespace}/${name}/${provider}/versions"
  RESPONSE=$(curl -s "$API_URL")

  if [[ -z "$RESPONSE" || "$RESPONSE" == "null" ]]; then
    echo "⚠️ Failed to fetch latest version for \`${MODULE_PATH}\` (API error)" | tee -a "$OUTPUT_FILE"
    continue
  fi

  LATEST_VERSION=$(echo "$RESPONSE" | jq -r '.modules[0].versions | map(.version) | sort | last')

  if [[ -z "$LATEST_VERSION" || "$LATEST_VERSION" == "null" ]]; then
    echo "⚠️ Could not determine latest version for \`${MODULE_PATH}\`" | tee -a "$OUTPUT_FILE"
    continue
  fi

  if [[ "$USED_VERSION" == "$LATEST_VERSION" ]]; then
    echo "✅ \`${MODULE_PATH}\` is up to date (**$USED_VERSION**)" | tee -a "$OUTPUT_FILE"
  else
    echo "❌ \`${MODULE_PATH}\` is outdated (used: **$USED_VERSION**, latest: **$LATEST_VERSION**)" | tee -a "$OUTPUT_FILE"
  fi

done < "$TMP_FILE"

# Clean up temporary file
rm -f "$TMP_FILE"
