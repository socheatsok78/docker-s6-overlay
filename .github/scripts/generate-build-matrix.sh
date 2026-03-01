#!/usr/bin/env bash
set -euo pipefail

# This script detects files changed in a pull request compared to the main branch.
# It looks for Dockerfiles among the changed files and generates a build matrix accordingly.
# Example:
# library/{version}/Dockerfile

GITHUB_OUTPUT=${GITHUB_OUTPUT:-/dev/null}

RUNNER_TEMP=${RUNNER_TEMP:-$(pwd)}
BUILD_MATRIX_MANIFEST=$(mktemp -p "${RUNNER_TEMP}")

echo "File changed:"
for file in library/*/docker-bake.hcl; do
	echo "- ${file}"
	if [[ "${file}" == *"/.empty" ]] || [[ "${file}" == *"/Dockerfile" ]] || [[ "${file}" == *"/docker-bake.hcl" ]]; then
		# Extract target and version from the file path
		version=$(echo "${file}" | cut -d'/' -f2)
		# Add to build matrix
		echo "{\"version\":\"${version}\"}" >> "$BUILD_MATRIX_MANIFEST"
	fi
done

# Build JSON array and write to GITHUB_OUTPUT, quoting to prevent word splitting.
echo "Generating build matrix..."
cat "$BUILD_MATRIX_MANIFEST" | sort -r | uniq | jq -s '.'

# Set the output variable for GitHub Actions
matrix_json=$(cat "$BUILD_MATRIX_MANIFEST" | sort | uniq | jq -sc '.')
echo "matrix=${matrix_json}" >> "$GITHUB_OUTPUT"

# Clean up
rm -f "$BUILD_MATRIX_MANIFEST" || true
