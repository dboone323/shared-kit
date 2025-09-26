#!/bin/bash

# AI Learning System Validation and Monitoring Dashboard
# Consolidated validator for all projects in the Quantum workspace

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Logging helpers
print_header() { echo -e "${PURPLE}[AI-MONITOR]${NC} ${CYAN}$1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_status() { echo -e "${BLUE}🔄 $1${NC}"; }
print_result() { echo -e "${GREEN}📊 $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
readonly REPO_ROOT
readonly PROJECTS_ROOT="${REPO_ROOT}/Projects"

if [[ ! -d "${PROJECTS_ROOT}" ]]; then
	print_error "Projects directory not found at ${PROJECTS_ROOT}"
	exit 1
fi

declare -a PROJECTS=()

initialise_projects() {
	if [[ -n ${AI_VALIDATOR_PROJECTS:-} ]]; then
		IFS=',' read -r -a PROJECTS <<<"${AI_VALIDATOR_PROJECTS}"
		local i
		for i in "${!PROJECTS[@]}"; do
			PROJECTS[$i]="$(echo "${PROJECTS[$i]}" | xargs)"
		done
	else
		while IFS= read -r dir; do
			local name
			name="$(basename "${dir}")"
			if [[ ${name} == .* ]] || [[ ${name} == '"' ]] || [[ ! ${name} =~ [A-Za-z0-9] ]]; then
				continue
			fi
			PROJECTS+=("${name}")
		done < <(find "${PROJECTS_ROOT}" -maxdepth 1 -mindepth 1 -type d -print | sort)
	fi
}

initialise_projects

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
	print_warning "No projects detected under ${PROJECTS_ROOT}."
fi

resolve_project_path() {
	local project="$1"
	printf '%s' "${PROJECTS_ROOT}/${project}"
}

learning_script_path() {
	local project="$1"
	printf '%s' "$(resolve_project_path "${project}")/Tools/Automation/adaptive_learning_system.sh"
}

project_config_path() {
	local project="$1"
	printf '%s' "$(resolve_project_path "${project}")/Tools/Automation/project_config.sh"
}

learning_data_dir() {
	local project="$1"
	printf '%s' "$(resolve_project_path "${project}")/.ai_learning_system"
}

mcp_actions_dir() {
	local project="$1"
	printf '%s' "$(resolve_project_path "${project}")/.github/actions"
}

workflows_dir() {
	local project="$1"
	printf '%s' "$(resolve_project_path "${project}")/.github/workflows"
}

project_exists() {
	local project="$1"
	[[ -d "$(resolve_project_path "${project}")" ]]
}

has_learning_script() {
	local project="$1"
	[[ -f "$(learning_script_path "${project}")" ]]
}

has_project_config() {
	local project="$1"
	[[ -f "$(project_config_path "${project}")" ]]
}

count_learning_runs() {
	local project="$1"
	local data_dir
	data_dir="$(learning_data_dir "${project}")"
	if [[ -d "${data_dir}" ]]; then
		find "${data_dir}" -type f -name '*.json' -print 2>/dev/null | wc -l | awk '{print $1}'
	else
		echo 0
	fi
}

count_mcp_actions() {
	local project="$1"
	local base
	base="$(mcp_actions_dir "${project}")"
	local count=0
	local action
	for action in mcp-auto-fix mcp-failure-prediction; do
		if [[ -d "${base}/${action}" ]]; then
			count=$((count + 1))
		fi
	done
	echo "${count}"
}

count_workflows() {
	local project="$1"
	local dir
	dir="$(workflows_dir "${project}")"
	if [[ -d "${dir}" ]]; then
		find "${dir}" -maxdepth 1 -type f -name '*.yml' -print 2>/dev/null | wc -l | awk '{print $1}'
	else
		echo 0
	fi
}

list_ai_workflows() {
	local project="$1"
	local dir
	dir="$(workflows_dir "${project}")"
	local matches=()
	if [[ -d "${dir}" ]]; then
		while IFS= read -r file; do
			if grep -qiE 'ai|learning' "${file}" 2>/dev/null; then
				matches+=("$(basename "${file}")")
			fi
		done < <(find "${dir}" -maxdepth 1 -type f -name '*.yml' -print 2>/dev/null)
	fi
	printf '%s' "${matches[*]-}"
}

test_ai_learning_functionality() {
	print_header "Validating adaptive learning tooling across projects"
	local projects_checked=0
	local healthy_projects=0

	for project in "${PROJECTS[@]}"; do
		((projects_checked++))

		if ! project_exists "${project}"; then
			print_warning "${project}: project directory missing"
			continue
		fi

		print_status "${project}: evaluating learning system setup"

		local all_checks_passed=true
		local run_count
		run_count="$(count_learning_runs "${project}")"

		if has_learning_script "${project}"; then
			print_success "  • adaptive_learning_system.sh found"
		else
			print_warning "  • adaptive_learning_system.sh missing"
			all_checks_passed=false
		fi

		if has_project_config "${project}"; then
			print_success "  • project_config.sh available"
		else
			print_warning "  • project_config.sh missing"
			all_checks_passed=false
		fi

		if [[ "${run_count}" -gt 0 ]]; then
			print_status "  • ${run_count} learning dataset(s) detected"
		else
			print_warning "  • no learning datasets found"
		fi

		if [[ "${all_checks_passed}" == true ]]; then
			((healthy_projects++))
			print_result "  → ${project} ready for AI learning automation"
		else
			print_warning "  → ${project} requires follow-up"
		fi
		echo ""
	done

	if (( projects_checked > 0 )); then
		local percent=$((healthy_projects * 100 / projects_checked))
		print_result "Validation summary: ${healthy_projects}/${projects_checked} projects ready (${percent}%)"
	else
		print_warning "No projects available for validation."
	fi
}

test_enhanced_mcp_actions() {
	print_header "Checking enhanced MCP actions"
	local projects_checked=0
	local compliant=0

	for project in "${PROJECTS[@]}"; do
		((projects_checked++))

		if ! project_exists "${project}"; then
			print_warning "${project}: project directory missing"
			continue
		fi

		local actions_present
		actions_present="$(count_mcp_actions "${project}")"

		if [[ "${actions_present}" -eq 2 ]]; then
			((compliant++))
			print_success "${project}: both MCP actions available (2/2)"
		else
			print_warning "${project}: ${actions_present}/2 MCP actions available"
		fi
	done

	if (( projects_checked > 0 )); then
		local percent=$((compliant * 100 / projects_checked))
		print_result "MCP action coverage: ${compliant}/${projects_checked} projects (${percent}%)"
	else
		print_warning "No projects available for MCP action checks."
	fi
}

generate_learning_analytics() {
	print_header "Generating AI learning analytics"

	local analytics_file
	analytics_file="${REPO_ROOT}/AI_LEARNING_ANALYTICS_$(date +%Y%m%d_%H%M%S).md"
	local total_runs=0
	local total_workflows=0
	local report_rows=""

	for project in "${PROJECTS[@]}"; do
		if ! project_exists "${project}"; then
			continue
		fi

		local run_count workflow_count learning_dir
		run_count="$(count_learning_runs "${project}")"
		workflow_count="$(count_workflows "${project}")"
		learning_dir="$(learning_data_dir "${project}")"

		total_runs=$((total_runs + run_count))
		total_workflows=$((total_workflows + workflow_count))

		local learning_status
		if [[ -d "${learning_dir}" ]]; then
			learning_status="present"
		else
			learning_status="missing"
		fi

		report_rows+="| ${project} | ${run_count} | ${workflow_count} | ${learning_status} |\n"
		print_status "${project}: runs=${run_count}, workflows=${workflow_count}, data=${learning_status}"
	done

	cat >"${analytics_file}" <<EOF
# AI Learning Analytics

**Generated:** $(date)
**Repository Root:** ${REPO_ROOT}

| Project | Learning Runs | Workflow Count | Learning Data |
|---------|----------------|----------------|---------------|
EOF

	printf '%b' "${report_rows}" >>"${analytics_file}"

	cat >>"${analytics_file}" <<EOF

**Totals**

- Learning datasets discovered: ${total_runs}
- Workflow files inspected: ${total_workflows}
- Projects analysed: ${#PROJECTS[@]}

EOF

	print_result "Analytics report written to ${analytics_file}"
}

monitor_active_workflows() {
	print_header "Monitoring AI-focused workflows"

	for project in "${PROJECTS[@]}"; do
		if ! project_exists "${project}"; then
			print_warning "${project}: project directory missing"
			continue
		fi

		local ai_workflows
		ai_workflows="$(list_ai_workflows "${project}")"

		if [[ -n "${ai_workflows}" ]]; then
			print_success "${project}: AI-focused workflows detected"
			local workflow
			for workflow in ${ai_workflows}; do
				print_status "  • ${workflow}"
			done
		else
			print_warning "${project}: no AI-specific workflows found"
		fi
	done
}

create_validation_report() {
	print_header "Creating comprehensive validation report"

	local report_file
	report_file="${REPO_ROOT}/AI_LEARNING_VALIDATION_$(date +%Y%m%d_%H%M%S).md"

	cat >"${report_file}" <<EOF
# AI Learning System Validation Report

**Generated:** $(date)
**Validator:** AI Learning Monitoring Dashboard

| Project | Learning Script | Project Config | MCP Actions | Learning Datasets |
|---------|-----------------|----------------|-------------|-------------------|
EOF

	for project in "${PROJECTS[@]}"; do
		if ! project_exists "${project}"; then
			continue
		fi

		local learning_status config_status actions_present runs

		if has_learning_script "${project}"; then
			learning_status="✅"
		else
			learning_status="⚠️"
		fi

		if has_project_config "${project}"; then
			config_status="✅"
		else
			config_status="⚠️"
		fi

		actions_present="$(count_mcp_actions "${project}")"
		if [[ "${actions_present}" -eq 2 ]]; then
			actions_present="✅ 2/2"
		else
			actions_present="⚠️ ${actions_present}/2"
		fi

		runs="$(count_learning_runs "${project}")"

		cat >>"${report_file}" <<EOF
| ${project} | ${learning_status} | ${config_status} | ${actions_present} | ${runs} |
EOF
	done

	print_result "Validation report written to ${report_file}"
}

run_dashboard() {
	print_header "AI Learning System Monitoring Dashboard"
	echo ""
	test_ai_learning_functionality
	echo ""
	test_enhanced_mcp_actions
	echo ""
	monitor_active_workflows
	echo ""
	generate_learning_analytics
	echo ""
	create_validation_report
}

main() {
	local command="${1:-dashboard}"
	case "${command}" in
		"test")
			test_ai_learning_functionality
			;;
		"actions")
			test_enhanced_mcp_actions
			;;
		"analytics")
			generate_learning_analytics
			;;
		"monitor")
			monitor_active_workflows
			;;
		"validate")
			create_validation_report
			;;
		"dashboard"|"full")
			run_dashboard
			;;
		"help"|"--help"|-h)
			cat <<EOF
🔍 AI Learning System Validation and Monitoring Dashboard

Usage: $0 [COMMAND]

Commands:
  test          Test AI learning system functionality
  actions       Verify enhanced MCP actions
  analytics     Generate a learning analytics report
  monitor       Inspect AI-focused workflow files
  validate      Create a comprehensive validation report
  dashboard     Run the full monitoring dashboard (default)
  help          Show this help message

Set AI_VALIDATOR_PROJECTS to a comma-separated list to restrict the
validation scope, e.g.:

  AI_VALIDATOR_PROJECTS="CodingReviewer,HabitQuest" $0 test

EOF
			;;
		*)
			print_error "Unknown command: ${command}"
			echo "Use '$0 help' for usage information"
			exit 1
			;;
	 esac
}

main "$@"
