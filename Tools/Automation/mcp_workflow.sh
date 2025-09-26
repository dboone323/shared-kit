#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find_repo_root() {
	local dir="${SCRIPT_DIR}"
	while [[ "${dir}" != "/" ]]; do
		if [[ -d "${dir}/.git" ]]; then
			echo "${dir}"
			return 0
		fi
		dir="$(dirname "${dir}")"
	done
	echo "Unable to locate repository root from ${SCRIPT_DIR}" >&2
	exit 1
}

REPO_ROOT="$(find_repo_root)"
exec "${REPO_ROOT}/Tools/Automation/mcp_workflow.sh" "$@"
