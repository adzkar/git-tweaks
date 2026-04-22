#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

print_header() {
  echo ""
  echo -e "${BOLD}git chain-sync${RESET}"
  echo -e "${DIM}────────────────────────────────────────${RESET}"
}

print_step() {
  echo -e "\n${CYAN}[${1}/${2}]${RESET} ${BOLD}${3}${RESET} ${DIM}← ${4}${RESET}"
}

print_ok()   { echo -e "  ${GREEN}✓${RESET} ${1}"; }
print_fail() { echo -e "  ${RED}✗${RESET} ${1}"; }
print_info() { echo -e "  ${DIM}→${RESET} ${1}"; }

ask_select() {
  local prompt="$1"
  shift
  local options=("$@")
  echo -e "\n${BOLD}${prompt}${RESET}"
  for i in "${!options[@]}"; do
    echo -e "  ${CYAN}$((i+1)).${RESET} ${options[$i]}"
  done
  while true; do
    printf "  choice [1-${#options[@]}]: "
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
      SELECTED_IDX=$((choice-1))
      SELECTED_VAL="${options[$SELECTED_IDX]}"
      return
    fi
    echo -e "  ${YELLOW}invalid — enter a number between 1 and ${#options[@]}${RESET}"
  done
}

run_build() {
  local cmd="$1"
  print_info "running: ${cmd}"
  if ! eval "$cmd" > /tmp/chain-sync-build.log 2>&1; then
    print_fail "build failed on branch '$(git branch --show-current)'"
    echo ""
    echo -e "${DIM}── build output ─────────────────────────${RESET}"
    tail -20 /tmp/chain-sync-build.log
    echo -e "${DIM}─────────────────────────────────────────${RESET}"
    echo ""
    echo -e "${RED}chain stopped. fix the build then re-run.${RESET}"
    exit 1
  fi
  print_ok "build passed"
}

# ── validate args ─────────────────────────

if [ "$#" -lt 2 ]; then
  echo -e "${RED}error:${RESET} provide at least 2 branches."
  echo -e "${DIM}usage:  git chain-sync branch-a branch-b branch-c ...${RESET}"
  exit 1
fi

BRANCHES=("$@")

print_header

echo -e "\n${BOLD}branch chain:${RESET}"
for i in "${!BRANCHES[@]}"; do
  if [ $i -eq 0 ]; then
    printf "  ${CYAN}${BRANCHES[$i]}${RESET}"
  else
    printf " ${DIM}→${RESET} ${CYAN}${BRANCHES[$i]}${RESET}"
  fi
done
echo ""

# ── build check ───────────────────────────

BUILD_OPTIONS=(
  "npm run build"
  "npm run lint && npm run build"
  "npm run test"
  "custom (enter your own)"
  "skip build check"
)

ask_select "build check:" "${BUILD_OPTIONS[@]}"
BUILD_CHOICE=$SELECTED_IDX

case $BUILD_CHOICE in
  0) BUILD_CMD="npm run build" ;;
  1) BUILD_CMD="npm run lint && npm run build" ;;
  2) BUILD_CMD="npm run test" ;;
  3)
    printf "\n  enter build command: "
    read -r BUILD_CMD
    if [ -z "$BUILD_CMD" ]; then
      echo -e "${RED}error:${RESET} build command cannot be empty."
      exit 1
    fi
    ;;
  4) BUILD_CMD="" ;;
esac

if [ -n "$BUILD_CMD" ]; then
  echo -e "  ${DIM}→ will run:${RESET} ${BUILD_CMD}"
else
  echo -e "  ${DIM}→ skipping build checks${RESET}"
fi

# ── merge strategy ────────────────────────

MERGE_OPTIONS=(
  "git merge   (merge commit, safer for shared branches)"
  "git rebase  (linear history, requires force-push)"
)

ask_select "merge strategy:" "${MERGE_OPTIONS[@]}"
MERGE_STRATEGY=$SELECTED_IDX

if [ $MERGE_STRATEGY -eq 0 ]; then
  echo -e "  ${DIM}→ using: git merge${RESET}"
else
  echo -e "  ${DIM}→ using: git rebase (will force-push with --force-with-lease)${RESET}"
fi

# ── auto push ─────────────────────────────

PUSH_OPTIONS=(
  "yes — push each branch after sync"
  "no  — sync locally only (no push)"
)

ask_select "auto push to remote?" "${PUSH_OPTIONS[@]}"
AUTO_PUSH=$SELECTED_IDX

if [ $AUTO_PUSH -eq 0 ]; then
  echo -e "  ${DIM}→ will push each branch after sync${RESET}"
else
  echo -e "  ${DIM}→ local only, no push${RESET}"
fi

# ── confirm ───────────────────────────────

echo ""
echo -e "${DIM}────────────────────────────────────────${RESET}"
echo -e "${BOLD}ready to sync ${#BRANCHES[@]} branches.${RESET}$([ $AUTO_PUSH -eq 0 ] && echo " ${DIM}this will push to remote.${RESET}" || echo "")"
printf "continue? [y/N]: "
read -r confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}aborted.${RESET}"
  exit 0
fi

# ── sync loop ─────────────────────────────

TOTAL=$(( ${#BRANCHES[@]} - 1 ))

for i in "${!BRANCHES[@]}"; do
  CURR="${BRANCHES[$i]}"

  if [ $i -eq 0 ]; then
    echo -e "\n${DIM}── root branch ──────────────────────────${RESET}"
    print_info "checking out ${CURR}"
    git checkout "$CURR"
    print_info "pulling latest from origin/${CURR}"
    git pull origin "$CURR"
    if [ -n "$BUILD_CMD" ]; then
      run_build "$BUILD_CMD"
    fi
    print_ok "${CURR} is up to date"
    continue
  fi

  PREV="${BRANCHES[$((i-1))]}"
  print_step "$i" "$TOTAL" "$CURR" "$PREV"

  git checkout "$CURR"

  if [ $MERGE_STRATEGY -eq 0 ]; then
    print_info "merging ${PREV} into ${CURR}"
    git merge "$PREV" --no-edit
  else
    print_info "rebasing ${CURR} onto ${PREV}"
    git rebase "$PREV"
  fi

  if [ -n "$BUILD_CMD" ]; then
    run_build "$BUILD_CMD"
  fi

  if [ $AUTO_PUSH -eq 0 ]; then
    if [ $MERGE_STRATEGY -eq 0 ]; then
      git push origin "$CURR"
    else
      git push --force-with-lease origin "$CURR"
    fi
    print_ok "${CURR} synced and pushed"
  else
    print_ok "${CURR} synced locally"
  fi
done

# ── done ──────────────────────────────────

echo ""
echo -e "${DIM}────────────────────────────────────────${RESET}"
if [ $AUTO_PUSH -eq 1 ]; then
  echo -e "${GREEN}${BOLD}✓ all branches synced locally.${RESET} ${DIM}run git multiple-push to push when ready.${RESET}"
else
  echo -e "${GREEN}${BOLD}✓ all branches synced and pushed.${RESET}"
fi
ORIGIN="${BRANCHES[0]}"
git checkout "$ORIGIN"
echo -e "${DIM}back on ${ORIGIN}${RESET}\n"