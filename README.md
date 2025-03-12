# mu

> A productivity-focused CLI for switching between and interacting with local projects

`mu` is a CLI that allows you to switch your working directory to another local directory quickly. It also provides shortcuts for performing common operational tasks if that directory is a Git repo.

## TL;DR

First you need to teach `mu` where to look for your projects:

1. From Terminal, `cd` to the directory of a repo.
2. Run `mu add <project_key>` to add the current directory to the `mu` registry, where `<project_key>` is the key you wish to use to name this project.

From now on you can just run `mu cd <project_key>` to navigate to that project directly from Terminal. Better yet, you can run `mu project <project_key>` (or `mu p <project_key>` for short) to immediate open it with your default text editor (`mu` scans for Xcode project files and Android Studio projects first then falls back to VSCode/Sublime/Atom/TextMate respectively, depending on which editor is installed in your system).

## Install

Install mu via cURL:

```sh
$ curl -o- https://raw.githubusercontent.com/andrewscwei/mu/v1.5.0/install.sh | bash
```

## Uninstall

1. Remove `.mu` from home directory:
   ```sh
   $ rm -rf ~/.mu
   ```
2. Remove line `alias mu='. /<HOME_DIR>/.mu/mu.sh'` from any of the following profile config files:
   1. `~/.bashrc`
   2. `~/.profile`
   3. `~/.bash_profile`
   4. `~/.zshrc`

## Commands

```sh
Usage: mu <command> [args] or mu <command> -h for more info

Main Commands:
  add      Maps the current working directory to a project key (alias: a)
  cd       Changes the current working directory to the working directory of a project
  clean    Cleans the registry by reconciling invalid entries
  edit     Edits the registry file directly in the default text editor (USE WITH CAUTION)
  help     Provides access to additional info regarding specific commands (alias: h)
  list     Lists all current projects in the registry (aliases: ls, l)
  project  Opens a project in intended IDE (alias: p)
  remove   Removes a project from the registry (aliases: rm, r)

Git Commands:
  gist     Downloads all files from a gist to the working directory
  tag      Creates a tag in both local and remote Git repository
  untag    Deletes a tag from both local and remote Git repository
  changes  Scans for uncommitted changes and unpushed commits in all Git repos in the
           current directory (aliases: c)
```

### `mu add <project_key>`
Maps the current working directory to a project key. If you don't specify a project key, the name of the current working directory will be used.

### `mu cd <project_key_or_index>`
Changes the working directory to the working directory of a `mu` project.

### `mu list`
Lists all current projects managed by `mu`

### `mu project <project_key_or_index>`
Opens a `mu` project in designated IDE (supports Xcode/Sublime in respective priority).

### `mu remove <project_key_or_index>`
Removes a `mu` project from the `mu` registry. If you don't specify a project key or index, the name of the current working directory will be used.

> Whenever you run a command that expects a project key or index, you can optionally leave the key or index blank. The command infers it from the last used key. You can run `mu cache` to see what the last interacted project is.

> Whenever you run a command that expects a project key or index, you can use `.` to refer to the current working directory (`pwd`).

> Most commands have 1-letter short notations. For example, instead of doing `mu project` you can do `mu p`.
