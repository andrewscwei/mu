#!/usr/bin/env bash

{ # This ensures the entire script is downloaded

# Config.
VERSION="1.1.0"
SOURCE=https://raw.githubusercontent.com/andrewscwei/mu/v$VERSION/mu.sh

# Colors.
COLOR_PREFIX="\x1b["
COLOR_RESET=$COLOR_PREFIX"0m"
COLOR_BLACK=$COLOR_PREFIX"0;30m"
COLOR_RED=$COLOR_PREFIX"0;31m"
COLOR_GREEN=$COLOR_PREFIX"0;32m"
COLOR_ORANGE=$COLOR_PREFIX"0;33m"
COLOR_BLUE=$COLOR_PREFIX"0;34m"
COLOR_PURPLE=$COLOR_PREFIX"0;35m"
COLOR_CYAN=$COLOR_PREFIX"0;36m"
COLOR_LIGHT_GRAY=$COLOR_PREFIX"0;37m"

# Checks if a command is available.
#
# @param $1 Name of the command.
function cmd_exists() {
  type "$1" > /dev/null 2>&1
}

# Gets the default install path. This can be overridden when calling the
# download script by passing the `MU_DIR` variable.
function install_dir() {
  printf %s "${MU_DIR:-"$HOME/.mu"}"
}

# Installs mu as a script.
function install() {
  local dest="$(install_dir)"

  mkdir -p "$dest"

  if [ -f "$dest/mu.sh" ]; then
    echo -e "${COLOR_BLUE}mu: mu ${COLOR_ORANGE}is already installed in ${COLOR_CYAN}$dest${COLOR_ORANGE}, updating it instead...${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}mu: ${COLOR_RESET}Downloading ${COLOR_BLUE}mu${COLOR_RESET} to ${COLOR_CYAN}$dest${COLOR_RESET}"
  fi

  # Download the script.
  curl --compressed -q -s "$SOURCE" -o "$dest/mu.sh" || {
    echo >&2 "${COLOR_BLUE}mu: ${COLOR_RED}Failed to download from ${COLOR_CYAN}$SOURCE${COLOR_RESET}"
    return 1
  }

  # Make script executable.
  chmod a+x "$dest/mu.sh" || {
    echo >&2 "${COLOR_BLUE}mu: ${COLOR_RED}Failed to mark ${COLOR_CYAN}$dest/mu.sh${COLOR_RESET} as executable"
    return 3
  }
}

# Main process
function main() {
  # Download and install the script.
  if cmd_exists curl; then
    install
  else
    echo >&2 "${COLOR_BLUE}mu: ${COLOR_RED}You need ${COLOR_CYAN}curl${COLOR_RED} to install ${COLOR_BLUE}mu${COLOR_RESET}"
    exit 1
  fi

  # Edit Bash and ZSH profile files to set up mu.
  local dest="$(install_dir)"
  local bashprofile=""
  local zshprofile=""
  local sourcestr="\nalias mu='. ${dest}/mu.sh'\n"

  if [ -f "$HOME/.bashrc" ]; then
    bashprofile="$HOME/.bashrc"
  elif [ -f "$HOME/.profile" ]; then
    bahsprofile="$HOME/.profile"
  elif [ -f "$HOME/.bash_profile" ]; then
    bashprofile="$HOME/.bash_profile"
  fi

  if [ -f "$HOME/.zshrc" ]; then
    zshprofile="$HOME/.zshrc"
  fi

  if [[ "$bashprofile" == "" ]] && [[ "$zshprofile" == "" ]]; then
    echo -e "${COLOR_BLUE}mu: ${COLOR_RESET}Bash profile not found, tried ${COLOR_CYAN}~/.bashrc${COLOR_RESET}, ${COLOR_CYAN}~/.zshrc${COLOR_RESET}, ${COLOR_CYAN}~/.profile${COLOR_RESET} and ${COLOR_CYAN}~/.bash_profile${COLOR_RESET}"
    echo -e "     Create one of them and run this script again"
    echo -e "     OR"
    echo -e "     Append the following lines to the correct file yourself:"
    echo -e "     ${COLOR_CYAN}${sourcestr}${COLOR_RESET}"
    exit 1
  fi

  if [[ "$bashprofile" != "" ]]; then
    if ! command grep -qc '/mu.sh' "$bashprofile"; then
      echo -e "${COLOR_BLUE}mu: ${COLOR_RESET}Appending ${COLOR_BLUE}mu${COLOR_RESET} source string to ${COLOR_CYAN}$bashprofile${COLOR_RESET}"
      command printf "${sourcestr}" >> "$bashprofile"
    else
      echo -e "${COLOR_BLUE}mu: mu ${COLOR_RESET}source string is already in ${COLOR_CYAN}$bashprofile${COLOR_RESET}"
    fi
  fi

  if [[ "$zshprofile" != "" ]]; then
    if ! command grep -qc '/mu.sh' "$zshprofile"; then
      echo -e "${COLOR_BLUE}mu: ${COLOR_RESET}Appending ${COLOR_BLUE}mu${COLOR_RESET} source string to ${COLOR_CYAN}$zshprofile${COLOR_RESET}"
      command printf "${sourcestr}" >> "$zshprofile"
    else
      echo -e "${COLOR_BLUE}mu: mu ${COLOR_RESET}source string is already in ${COLOR_CYAN}$zshprofile${COLOR_RESET}"
    fi
  fi

  echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}Installation complete. Close and reopen your terminal to start using ${COLOR_BLUE}mu${COLOR_RESET}"

  # Source mu
  \. "$dest/mu.sh"
}

main

} # This ensures the entire script is downloaded
