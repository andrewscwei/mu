#!/bin/bash

# mu CLI
# © Andrew Wei
#
# This software is released under the MIT License:
# http://www.opensource.org/licenses/mit-license.php

{ # This ensures the entire script is downloaded #

# Config.
VERSION="1.0.0"

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

# Paths.
PATH_ROOT=$(dirname ${BASH_SOURCE[0]-$0})
PATH_REPOSITORY=$PATH_ROOT"/registry"
PATH_CACHE=$PATH_ROOT"/registry-cache"

# Checks if a command is available
#
# @param $1 Name of the command.
function cmd_exists() {
  type "$1" > /dev/null 2>&1
}

# Serializes the registry into an array of project entries in the form of
# "key":"path" string pair. This operation stores the array of project entries
# into `PROJECT_LIST` and its length into `PROJECT_LENGTH`.
function serialize_repo() {
  # Reset global variable.
  PROJECT_LIST=()

  if [ -e $PATH_REPOSITORY ]; then
    # Read line-by-line.
    while read l; do
      if [[ $l == *:* ]]; then
        PROJECT_LIST=("${PROJECT_LIST[@]}" "$l")
      else
        continue
      fi
    done <$PATH_REPOSITORY
  fi

  PROJECT_LENGTH=${#PROJECT_LIST[@]}
}

# Parses a project entry in the form of "key":"path" string pair and stores the
# key and the path into `TMP_PROJECT_ALIAS` and `TMP_PROJECT_PATH` respectively.
#
# @param $1 The "key":"path" string pair.
function decode_project_pair() {
  if [[ "$1" == "" ]]; then return; fi

  # Store the key and path globally. Account for 1-base arrays in ZSH.
  if [ -n "$ZSH_VERSION" ]; then
    local arr=("${(@s/:/)1}")
    TMP_PROJECT_ALIAS="${arr[1]}"
    TMP_PROJECT_PATH="${arr[2]}"
  else
    local arr=(${1//\:/ })
    TMP_PROJECT_ALIAS="${arr[0]}"
    TMP_PROJECT_PATH="${arr[1]}"
  fi
}

# Looks up the repo by key, index, or cache and stores the matching project pair
# globally.
#
# @param $1 Project key or index
function get_project_pair() {
  if [[ "$1" == "" ]]; then
    get_cache
    get_project_pair_by_alias $PROJECT_CACHE
    return
  fi

  # . means get the project key from cache.
  if [[ "$1" == "." ]]; then
    get_project_pair_by_path "$(pwd)"
    return
  fi

  # Check if getting project pair by key or index.
  [[ $1 =~ ^-?[0-9]+$ ]] && use_idx=1 || use_idx=0

  if (($use_idx == 1)); then
    get_project_pair_by_index $1
  else
    get_project_pair_by_alias $1
  fi
}

# Looks up the repo by key and stores the matching project pair globally.
#
# @param $1 Project key
function get_project_pair_by_alias() {
  if [[ "$1" != "" ]]; then
    serialize_repo

    # Iterate through the list of projects.
    for ((i = 1; i <= $PROJECT_LENGTH; i++)); do
      local idx=$([ -n "$ZSH_VERSION" ] && echo "$i" || echo "$((i-1))")
      decode_project_pair "${PROJECT_LIST[$idx]}"

      if [[ "$TMP_PROJECT_ALIAS" == "$1" ]]; then
        return
      fi
    done
  fi

  TMP_PROJECT_ALIAS=""
  TMP_PROJECT_PATH=""
}

# Looks up the repo by index and stores the matching project pair globally.
#
# @param $1 Project index
function get_project_pair_by_index() {
  if [[ "$1" != "" ]]; then
    serialize_repo

    # Iterate through the list of projects.
    for ((i = 1; i <= $PROJECT_LENGTH; i++)); do
      local idx=$([ -n "$ZSH_VERSION" ] && echo "$i" || echo "$((i-1))")
      decode_project_pair "${PROJECT_LIST[$idx]}"

      if (($i == $1)); then
        return
      fi
    done
  fi

  TMP_PROJECT_ALIAS=""
  TMP_PROJECT_PATH=""
}

# Looks up the repo by path and stores the matching project pair globally.
#
# @param $1 Project path
function get_project_pair_by_path() {
  if [[ "$1" != "" ]]; then
    serialize_repo

    # Iterate through the list of projects.
    for ((i = 1; i <= $PROJECT_LENGTH; i++)); do
      local idx=$([ -n "$ZSH_VERSION" ] && echo "$i" || echo "$((i-1))")
      decode_project_pair "${PROJECT_LIST[$idx]}"

      if [[ "$TMP_PROJECT_PATH" == "$1" ]]; then
        return
      fi
    done
  fi

  TMP_PROJECT_ALIAS=""
  TMP_PROJECT_PATH=""
}

# Stores the cached key globally.
function get_cache() {
  if [ -e $PATH_CACHE ]; then
    PROJECT_CACHE=$(<$PATH_CACHE)
  else
    PROJECT_CACHE=""
  fi
}

# Writes the last used project key into cache.
#
# @param $1 Project key to be cached
function set_cache() {
  if [[ "$1" == "" ]]; then return; fi

  # Iterate through the list of projects.
  for ((i = 1; i <= $PROJECT_LENGTH; i++)); do
    local idx=$([ -n "$ZSH_VERSION" ] && echo "$i" || echo "$((i-1))")
    decode_project_pair "${PROJECT_LIST[$idx]}"

    if [[ "$TMP_PROJECT_ALIAS" == "$1" ]]; then
      echo -e $1 >|$PATH_CACHE
      return
    fi
  done

  echo -e "${COLOR_BLUE}mu: ${COLOR_RED}ERR! ${COLOR_RESET}Problem writing cache"
}

# Opens the provided path in the preferred editor.
#
# @param $1 Path to open.
function open_in_editor() {
  if [[ "$1" == "" ]]; then return; fi

  if cmd_exists "code"; then
    code "$1"
  elif cmd_exists "subl"; then
    subl "$1"
  elif cmd_exists "atom"; then
    atom "$1"
  elif cmd_exists "mate"; then
    mate "$1"
  else
    echo -e "${COLOR_BLUE}mu: ${COLOR_RESET}No editors available"
  fi
}

# Shows the current cached project key.
function cmd_cache() {
  get_cache

  if [[ "$PROJECT_CACHE" == "" ]]; then
    echo -e "${COLOR_BLUE}mu: ${COLOR_RESET}The cache is empty"
  else
    echo -e "${COLOR_BLUE}mu: ${COLOR_RESET}Current project in cache: ${COLOR_CYAN}$PROJECT_CACHE${COLOR_RESET}"
  fi
}

# Adds to the registry the current directory associated with the specified
# project key.
#
# @param [$1] Key of project. Leave blank or use "." to use the name of the
#             current directory.
function cmd_add() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}add <project_alias>${COLOR_RESET} (alias: ${COLOR_CYAN}a${COLOR_RESET})"
    echo
    echo -e "Maps the current working directory to <project_alias>. If there already exists a project with the same key, its working directory will be replaced."
    return
  fi

  serialize_repo

  local key="$1"
  local dir="$(pwd)"
  local buffer=""
  local check=0

  if [[ "$key" == "" ]] || [[ "$key" == "." ]]; then
    key="${PWD##*/}"
  fi

  # Iterate through the list of projects.
  for ((i = 1; i <= $PROJECT_LENGTH; i++)); do
    local idx=$([ -n "$ZSH_VERSION" ] && echo "$i" || echo "$((i-1))")
    local pair=${PROJECT_LIST[$idx]}

    decode_project_pair "$pair"

    # If the specified project key already exists...
    if [[ "$TMP_PROJECT_ALIAS" == "$key" ]]; then
      check=1
      buffer="$buffer$TMP_PROJECT_ALIAS:${dir}\n"
      # Else just add the current line to the output buffer.
    else
      buffer="$buffer$pair\n"
    fi
  done

  if [[ $check == 0 ]]; then
    buffer="$buffer$key:${dir}\n"
    echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}Mapped ${COLOR_CYAN}$key ${COLOR_RESET}to ${COLOR_CYAN}${dir}${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}Remapped ${COLOR_CYAN}$key${COLOR_RESET} to ${COLOR_CYAN}${dir}${COLOR_RESET}"
  fi

  echo -e $buffer >|$PATH_REPOSITORY

  serialize_repo
  set_cache $key
}

# Navigates to the root path of a project in Terminal. Either specify a string
# representing the project key or a number prefixed by '#' representing the
# index.
#
# @param $1 Project key or index
function cmd_cd() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}cd <project_alias_or_index>${COLOR_RESET}"
    echo
    echo -e "Changes the current working directory to that of the specified ${COLOR_CYAN}<project_alias_or_index>${COLOR_RESET}."
    return
  fi

  if [[ "$1" == "-r" ]]; then
    cd $PATH_ROOT
    return
  fi

  get_project_pair $1

  if [[ "$TMP_PROJECT_ALIAS" != "" ]]; then
    set_cache $TMP_PROJECT_ALIAS
    cd "$TMP_PROJECT_PATH"

    return
  fi

  echo -e "${COLOR_BLUE}mu: ${COLOR_RED}ERR! ${COLOR_RESET}Project with reference ${COLOR_CYAN}$1${COLOR_RESET} not found"
}

# Tidies up the registry file, removing blank lines and fixing bad formatting.
function cmd_clean() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}clean${COLOR_RESET}"
    echo
    echo -e "Scans the registry and reconsiles invalid project entries."
    return
  fi

  serialize_repo

  local count=0
  local buffer=""

  # Iterate through the list of projects.
  for ((i = 1; i <= $PROJECT_LENGTH; i++)); do
    local idx=$([ -n "$ZSH_VERSION" ] && echo "$i" || echo "$((i-1))")
    local pair=${PROJECT_LIST[$idx]}

    decode_project_pair "$pair"

    # Store entry in buffer if it is valid. If invalid it will not be recorded,
    # thus 'cleaned'.
    if [[ "$pair" != "" ]] && [[ "$TMP_PROJECT_ALIAS" != "" ]] && [[ "$TMP_PROJECT_PATH" != "" ]]; then
      buffer="$buffer$pair\n"
    else
      count=$((count + 1))
    fi
  done

  echo -e $buffer >|$PATH_REPOSITORY
  echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}Reconciled $count project(s)"
}

# Lists all the projects in the registry.
function cmd_list() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}list${COLOR_RESET} (aliases: ${COLOR_CYAN}ls${COLOR_RESET}, ${COLOR_CYAN}l${COLOR_RESET})"
    echo
    echo -e "Lists all the current projects in the registry."
    return
  fi

  # Update PROJECT_LIST array.
  serialize_repo

  local output=""

  if (($PROJECT_LENGTH == 0)); then
    output="${output}${COLOR_BLUE}mu: ${COLOR_RED}ERR! ${COLOR_RESET}There are no projects in the registry."
  else
    output="${output}${COLOR_BLUE}mu: ${COLOR_RESET}Found ${COLOR_PURPLE}$PROJECT_LENGTH${COLOR_RESET} project(s) in the registry"
    output="${output}\n\n"

    for ((i = 1; i <= $PROJECT_LENGTH; i++)); do
      local idx=$([ -n "$ZSH_VERSION" ] && echo "$i" || echo "$((i-1))")
      local pair=${PROJECT_LIST[$idx]}

      decode_project_pair "$pair"

      output="${output}$i. ${COLOR_CYAN}$TMP_PROJECT_ALIAS${COLOR_RESET}: $TMP_PROJECT_PATH"

      if (($idx != $PROJECT_LENGTH)); then
        output="${output}\n"
      fi
    done
  fi

  echo -e $output
}

# Edits the local registry.
function cmd_edit_registry() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}edit${COLOR_RESET}"
    echo
    echo -e "Edits the registry file directly in the default text editor ${COLOR_PURPLE}(USE WITH CAUTION)${COLOR_RESET}."
    return
  fi

  open_in_editor $PATH_REPOSITORY
}

# Opens a project in Finder. Either specify a string representing the project
# key or a number representing the index.
#
# @param $1 Project key or index
function cmd_open() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}open <project_alias_or_index>${COLOR_RESET} (aliases: ${COLOR_CYAN}o${COLOR_RESET})"
    echo
    echo -e "Opens a project in Finder specified by ${COLOR_CYAN}<project_alias_or_index>${COLOR_RESET} from the registry."
    return
  fi
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_RESET}No help data available regarding ${COLOR_RED}$1${COLOR_RESET} at this point"
    return
  fi

  if cmd_exists "open"; then
    # If arg is blank, open root directory of mu.
    if [[ "$1" == "-r" ]]; then
      open $PATH_ROOT
      echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}Opened root in Finder"
      return
    fi

    get_project_pair $1

    if [[ $TMP_PROJECT_ALIAS != "" ]]; then
      set_cache $TMP_PROJECT_ALIAS
      open "$TMP_PROJECT_PATH"
      echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}Opened project ${COLOR_CYAN}$TMP_PROJECT_ALIAS${COLOR_RESET} in Finder"
    else
      echo -e "${COLOR_BLUE}mu: ${COLOR_RED}ERR! ${COLOR_RESET}Project with reference ${COLOR_CYAN}$1${COLOR_RESET} not found"
    fi
  else
    echo -e "${COLOR_BLUE}mu: ${COLOR_RED}ERR! ${COLOR_RESET}This command is only available in macOS"
  fi
}

# Removes a project from the registry. Either specify a string representing the
# project key or a number representing the index.
#
# @param $1 Project key or index. Leave blank or specify "." to use the name of
#           the current directory.
function cmd_remove() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}remove <project_alias_or_index>${COLOR_RESET} (aliases: ${COLOR_CYAN}rm${COLOR_RESET}, ${COLOR_CYAN}r${COLOR_RESET})"
    echo
    echo -e "Removes a project specified by ${COLOR_CYAN}<project_alias_or_index>${COLOR_RESET} from the registry."
    return
  fi

  local key="$1"

  if [[ "$key" == "" ]] || [[ "$key" == "." ]]; then
    key="${PWD##*/}"
  fi

  [[ $key =~ ^-?[0-9]+$ ]] && use_idx=1 || use_idx=0

  serialize_repo

  local removed=0
  local buffer=""

  # Iterate through the list of projects.
  for ((i = 1; i <= $PROJECT_LENGTH; i++)); do
    local idx=$([ -n "$ZSH_VERSION" ] && echo "$i" || echo "$((i-1))")
    local pair=${PROJECT_LIST[$idx]}
    local skip=0

    decode_project_pair "$pair"

    # If arg is a project index...
    if (($use_idx == 1)) && (($i == $key)); then
      skip=1
      removed=1

      echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}Removed project ${COLOR_CYAN}$TMP_PROJECT_ALIAS${COLOR_RESET} at index ${COLOR_PURPLE}$i${COLOR_RESET}"

      # Else if arg is a project key...
    elif (($use_idx == 0)) && [ "$TMP_PROJECT_ALIAS" == "$key" ]; then
      skip=1
      removed=1

      echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}Removed project ${COLOR_CYAN}$TMP_PROJECT_ALIAS${COLOR_RESET} at index ${COLOR_PURPLE}$i${COLOR_RESET}"
    fi

    # If there was no match for this loop...
    if (($skip == 0)); then
      buffer="$buffer$pair\n"
    fi
  done

  # If nothing was removed, throw error.
  if (($removed == 0)); then
    if (($use_idx == 1)); then
      echo -e "${COLOR_BLUE}mu: ${COLOR_RED}ERR! ${COLOR_RESET}Index ${COLOR_PURPLE}$key${COLOR_RESET} is out of bounds"
    else
      echo -e "${COLOR_BLUE}mu: ${COLOR_RED}ERR! ${COLOR_RESET}Project with key ${COLOR_CYAN}$key${COLOR_RESET} not found"
    fi
  fi

  echo -e $buffer >|$PATH_REPOSITORY
}

# Opens a project from the registry. Either specify a string representing the
# project key or a number representing the index.
#
# @param $1 Project key or index
function cmd_project() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}project <project_alias_or_index>${COLOR_RESET} (alias: ${COLOR_CYAN}p${COLOR_RESET})"
    echo
    echo -e "Opens a project specified by ${COLOR_CYAN}<project_alias_or_index>${COLOR_RESET} in its intended IDE. The following IDEs will be scanned: Xcode, Android Studio, Sublime, Atom and TextMate. If an IDE cannot be inferred, this command will be ignored."
    return
  fi

  get_project_pair $1

  if [[ "$TMP_PROJECT_ALIAS" != "" ]]; then
    TARGET_PROJECT_FILE=""

    for file in "$TMP_PROJECT_PATH"/*; do
      # If *.xcworkspace file is found, use it immediately.
      if [[ "$file" == *"xcworkspace" ]]; then
        TARGET_PROJECT_FILE="$file"
        break
        # If *.xcodeproj is found, store it temporarily until another
        # project file with higher priority is found.
      elif [[ "$file" == *"xcodeproj" ]]; then
        if [[ "$TARGET_PROJECT_FILE" != *"xcworkspace" ]]; then
          TARGET_PROJECT_FILE="$file"
        fi
        # If *.sublime-project is found, store it temporarily until another
        # project file with higher priority is found.
      elif [[ "$file" == *".gradle" ]]; then
        echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}Found Android Studio project, opening project ${COLOR_CYAN}$TMP_PROJECT_ALIAS${COLOR_RESET} with ${COLOR_CYAN}Android Studio${COLOR_RESET}"
        open -a /Applications/Android\ Studio.app $TMP_PROJECT_PATH
        return
      elif [[ "$file" == *"sublime-project" ]]; then
        if [[ "$TARGET_PROJECT_FILE" != *"xcworkspace" ]] && [[ "$TARGET_PROJECT_FILE" != *"xcodeproj" ]]; then
          TARGET_PROJECT_FILE="$file"
        fi
      fi
    done

    if [[ "$TARGET_PROJECT_FILE" != "" ]]; then
      set_cache $TMP_PROJECT_ALIAS

      if [[ "$TARGET_PROJECT_FILE" == *"xcworkspace" ]]; then
        echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}Found Xcode workspace, opening project ${COLOR_CYAN}$TMP_PROJECT_ALIAS${COLOR_RESET} with ${COLOR_CYAN}Xcode${COLOR_RESET}"
      elif [[ "$TARGET_PROJECT_FILE" == *"xcodeproj" ]]; then
        echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}Found Xcode project, opening project ${COLOR_CYAN}$TMP_PROJECT_ALIAS${COLOR_RESET} with ${COLOR_CYAN}Xcode${COLOR_RESET}"
      elif [[ "$TARGET_PROJECT_FILE" == *"sublime-project" ]]; then
        echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}Found Sublime project, opening project ${COLOR_CYAN}$TMP_PROJECT_ALIAS${COLOR_RESET} with ${COLOR_CYAN}Sublime${COLOR_RESET}"
      fi

      open "$TARGET_PROJECT_FILE"
    else
      set_cache $TMP_PROJECT_ALIAS
      echo -e "${COLOR_BLUE}mu: ${COLOR_GREEN}OK ${COLOR_RESET}No unique project files found, opening project ${COLOR_CYAN}$TMP_PROJECT_ALIAS${COLOR_RESET} in preferred editor"
      open_in_editor "$TMP_PROJECT_PATH"
    fi

    return
  fi

  echo -e "${COLOR_BLUE}mu: ${COLOR_RED}ERR! ${COLOR_RESET}Project with reference ${COLOR_CYAN}$2${COLOR_RESET} not found"
}

# Displays the directory.
function cmd_directory() {
  echo
  echo -e "Usage: ${COLOR_BLUE}mu ${COLOR_CYAN}<command>${COLOR_RESET} or ${COLOR_BLUE}mu ${COLOR_CYAN}<command> -h${COLOR_RESET} for more info"
  echo
  echo -e "where ${COLOR_CYAN}<command>${COLOR_RESET} is one of:"
  echo -e "${COLOR_CYAN}        add${COLOR_RESET} - Maps the current working directory to a project key (alias: ${COLOR_CYAN}a${COLOR_RESET})"
  echo -e "${COLOR_CYAN}         cd${COLOR_RESET} - Changes the current working directory to the working directory of a project"
  echo -e "${COLOR_CYAN}      clean${COLOR_RESET} - Cleans the registry by reconciling invalid entries"
  echo -e "${COLOR_CYAN}       edit${COLOR_RESET} - Edits the registry file directly in the default text editor ${COLOR_PURPLE}(USE WITH CAUTION)${COLOR_RESET}"
  echo -e "${COLOR_CYAN}       help${COLOR_RESET} - Provides access to additional info regarding specific commands (alias: ${COLOR_CYAN}h${COLOR_RESET})"
  echo -e "${COLOR_CYAN}       list${COLOR_RESET} - Lists all current projects in the registry (aliases: ${COLOR_CYAN}ls${COLOR_RESET}, ${COLOR_CYAN}l${COLOR_RESET})"
  echo -e "${COLOR_CYAN}    project${COLOR_RESET} - Opens a project in intended IDE (alias: ${COLOR_CYAN}p${COLOR_RESET})"
  echo -e "${COLOR_CYAN}     remove${COLOR_RESET} - Removes a project from the registry (aliases: ${COLOR_CYAN}rm${COLOR_RESET}, ${COLOR_CYAN}r${COLOR_RESET})"
  echo
  echo -e "  GitHub:"
  echo -e "${COLOR_CYAN}       gist${COLOR_RESET} - Downloads all files from a gist to the working directory"
  echo -e "${COLOR_CYAN}         pr${COLOR_RESET} - Creates a local branch from the provided title, pushes it to remote and creates a PR from it with the same title"
  echo -e "${COLOR_CYAN}        tag${COLOR_RESET} - Creates a tag in both local and remote Git repository"
  echo -e "${COLOR_CYAN}      untag${COLOR_RESET} - Deletes a tag from both local and remote Git repository"
}

# Downloads all files from a Gist to the working directory individually. This
# function requires `jq`.
#
# @param $1 ID of the gist
#
# @see https://stedolan.github.io/jq/
function cmd_gist() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}gist <url>${COLOR_RESET}"
    echo
    echo -e "Downloads all the files from a Gist as specified by ${COLOR_CYAN}<url>${COLOR_RESET} to the working directory."
    return
  fi

  curl -sS --remote-name-all $(curl -sS https://api.github.com/gists/$1 | jq -r '.files[].raw_url')
}

# Creates a tag in both local and remote Git repository.
#
# @param $1 The tag to create.
function cmd_tag() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}tag <tag>${COLOR_RESET}"
    echo
    echo -e "Creates a ${COLOR_CYAN}<tag>${COLOR_RESET} in local and remote Git repository."
    return
  fi

  git tag $1
  git push --tags
}

# Deletes a tag from both local and remote Git repository.
#
# @param $1 The tag to delete.
function cmd_untag() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}untag <tag>${COLOR_RESET}"
    echo
    echo -e "Deletes ${COLOR_CYAN}<tag>${COLOR_RESET} from local and remote Git repository."
    return
  fi

  git tag -d $1
  git push -d origin $1
}

# Creates a local branch from the provided title, pushes it to remote and
# creates a PR from it with the same title.
#
# @param $1 The title of the PR.
function cmd_pr() {
  if [[ "$1" == "-h" ]]; then
    echo -e "${COLOR_PURPLE}HELP: ${COLOR_BLUE}mu ${COLOR_CYAN}pr <title>${COLOR_RESET}"
    echo
    echo -e "Creates a new local branch derived from ${COLOR_CYAN}<title>${COLOR_RESET}, pushes it to remote and creates a PR from it with the same ${COLOR_CYAN}<title>${COLOR_RESET}."
    return
  fi

  local branch_name=$(echo "$1" |
    sed 's/\([^:]*\):\{0,1\} \{0,1\}\(.*\)/\1\/\2/' | # Parse type
    tr '[:upper:]' '[:lower:]' | # Convert to lowercase
    tr -s ' ' | # Comporess consecutive spaces into one
    tr ' ' '-' | # Replace spaces with hyphens
    sed 's/^-//' | # Remove leading hyphen if any
    sed 's/\/-/\//g' # Remove hyphen after / if any
  )

  git checkout -b $branch_name
  git push origin $branch_name
  gh pr create -t $1
}

# Main process.
if   [[ "$1" == "" ]] || [[ "$1" == "help" ]] || [[ "$1" == "h" ]];        then cmd_directory $2
elif [[ "$1" == "add" ]] || [[ "$1" == "a" ]];                             then cmd_add $2
elif [[ "$1" == "cache" ]];                                                then cmd_cache $2
elif [[ "$1" == "cd" ]];                                                   then cmd_cd $2
elif [[ "$1" == "clean" ]];                                                then cmd_clean $2
elif [[ "$1" == "list" ]] || [[ "$1" == "ls" ]] || [[ "$1" == "l" ]];      then cmd_list $2
elif [[ "$1" == "edit" ]];                                                 then cmd_edit_registry $2
elif [[ "$1" == "open" ]] || [[ "$1" == "o" ]];                            then cmd_open $2
elif [[ "$1" == "remove" ]] || [[ "$1" == "rm" ]] || [[ "$1" == "r" ]];    then cmd_remove $2
elif [[ "$1" == "project" ]] || [[ "$1" == "p" ]];                         then cmd_project $2
elif [[ "$1" == "version" ]] || [[ "$1" == "-v" ]];                        then echo -e "v$VERSION"
elif [[ "$1" == "gist" ]];                                                 then cmd_gist $2
elif [[ "$1" == "pr" ]];                                                   then cmd_pr $2
elif [[ "$1" == "tag" ]];                                                  then cmd_tag $2
elif [[ "$1" == "untag" ]];                                                then cmd_untag $2
else echo -e "${COLOR_BLUE}mu: ${COLOR_RESET}Unsupported command:" $1
fi

} # This ensures the entire script is downloaded #
