#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

print_ok()   { echo -e "  ${GREEN}✓${RESET} ${1}"; }
print_fail() { echo -e "  ${RED}✗${RESET} ${1}"; }
print_info() { echo -e "  ${DIM}→${RESET} ${1}"; }

# ── validate args ─────────────────────────

if [ "$#" -lt 2 ]; then
  echo -e "${RED}error:${RESET} provide a remote and at least 1 branch."
  echo -e "${DIM}usage:  git multiple-push <remote> branch-a branch-b branch-c ...${RESET}"
  echo -e "${DIM}example: git multiple-push origin main branch-a branch-b${RESET}"
  exit 1
fi

REMOTE="$1"
shift
BRANCHES=("$@")

# ── header ────────────────────────────────

echo ""
echo -e "${BOLD}git multiple-push${RESET}"
echo -e "${DIM}────────────────────────────────────────${RESET}"

echo -e "\n${BOLD}remote:${RESET}  ${CYAN}${REMOTE}${RESET}"
echo -e "${BOLD}branches:${RESET}"
for b in "${BRANCHES[@]}"; do
  echo -e "  ${DIM}·${RESET} ${b}"
done

# ── push mode ─────────────────────────────

echo -e "\n${BOLD}push mode:${RESET}"
echo -e "  ${CYAN}1.${RESET} normal push"
echo -e "  ${CYAN}2.${RESET} force push  ${DIM}(--force-with-lease, safe force)${RESET}"
echo -e "  ${CYAN}3.${RESET} force push  ${DIM}(--force, destructive)${RESET}"

while true; do
  printf "  choice [1-3]: "
  read -r mode_choice
  if [[ "$mode_choice" =~ ^[123]$ ]]; then break; fi
  echo -e "  ${YELLOW}invalid — enter 1, 2, or 3${RESET}"
done

case $mode_choice in
  1) PUSH_FLAG="";                  MODE_LABEL="normal push" ;;
  2) PUSH_FLAG="--force-with-lease"; MODE_LABEL="force-with-lease" ;;
  3) PUSH_FLAG="--force";            MODE_LABEL="force (destructive)" ;;
esac

echo -e "  ${DIM}→ using: ${MODE_LABEL}${RESET}"

# ── set upstream? ─────────────────────────

echo -e "\n${BOLD}set upstream (-u)?${RESET}"
echo -e "  ${CYAN}1.${RESET} yes — set upstream tracking for each branch"
echo -e "  ${CYAN}2.${RESET} no  — push only, no tracking change"

while true; do
  printf "  choice [1-2]: "
  read -r upstream_choice
  if [[ "$upstream_choice" =~ ^[12]$ ]]; then break; fi
  echo -e "  ${YELLOW}invalid — enter 1 or 2${RESET}"
done

if [ "$upstream_choice" -eq 1 ]; then
  UPSTREAM_FLAG="-u"
  echo -e "  ${DIM}→ will set upstream for each branch${RESET}"
else
  UPSTREAM_FLAG=""
  echo -e "  ${DIM}→ no upstream tracking change${RESET}"
fi

# ── confirm ───────────────────────────────

echo ""
echo -e "${DIM}────────────────────────────────────────${RESET}"
echo -e "${BOLD}ready to push ${#BRANCHES[@]} branch(es) to ${REMOTE}.${RESET}"
printf "continue? [y/N]: "
read -r confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}aborted.${RESET}"
  exit 0
fi

# ── push loop ─────────────────────────────

echo ""
FAILED=()
PUSHED=()

for branch in "${BRANCHES[@]}"; do
  printf "  ${DIM}pushing${RESET} ${CYAN}${branch}${RESET}${DIM}...${RESET} "

  FLAGS=""
  [ -n "$PUSH_FLAG" ] && FLAGS="$FLAGS $PUSH_FLAG"
  [ -n "$UPSTREAM_FLAG" ] && FLAGS="$FLAGS $UPSTREAM_FLAG"
  CMD="git push$FLAGS $REMOTE $branch"

  if output=$(eval "$CMD" 2>&1); then
    echo -e "${GREEN}✓${RESET}"
    PUSHED+=("$branch")
  else
    echo -e "${RED}✗${RESET}"
    FAILED+=("$branch")
    echo -e "${DIM}${output}${RESET}"
  fi
done

# ── summary ───────────────────────────────

echo ""
echo -e "${DIM}────────────────────────────────────────${RESET}"

if [ ${#PUSHED[@]} -gt 0 ]; then
  echo -e "${GREEN}${BOLD}✓ pushed (${#PUSHED[@]}):${RESET}"
  for b in "${PUSHED[@]}"; do
    echo -e "  ${GREEN}·${RESET} ${b} ${DIM}→ ${REMOTE}/${b}${RESET}"
  done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
  echo ""
  echo -e "${RED}${BOLD}✗ failed (${#FAILED[@]}):${RESET}"
  for b in "${FAILED[@]}"; do
    echo -e "  ${RED}·${RESET} ${b}"
  done
  echo ""
  echo -e "${YELLOW}tip: if branches have diverged, re-run and choose force-with-lease.${RESET}"
  exit 1
fi

echo ""