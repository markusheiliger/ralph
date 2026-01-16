# Ralph CLI - Installation

Installing Ralph CLI is quite easy using the following command

- Using curl

  ```
  curl -fsSL https://raw.githubusercontent.com/markusheiliger/ralph/refs/heads/main/install.sh | bash
  ```

- Using wget

  ```
  wget -qO- https://raw.githubusercontent.com/markusheiliger/ralph/refs/heads/main/install.sh | bash
  ```

The script will - by default - download the ralph.tar.gz from the latest release on the https://github.com/markusheiliger/ralph repository.

## Options

| Option | Description |
|:-------|:------------|
| `--preview` | Install the latest preview release instead of stable |
| `--help`, `-h` | Show help message |

## Latest Preview Version

To install the latest preview version of the Ralph CLI, use the `--preview` flag:

- Using curl

  ```
  curl -fsSL https://raw.githubusercontent.com/markusheiliger/ralph/refs/heads/main/install.sh | bash -s -- --preview
  ```

- Using wget

  ```
  wget -qO- https://raw.githubusercontent.com/markusheiliger/ralph/refs/heads/main/install.sh | bash -s -- --preview
  ```

# Install Location

Ralph CLI is installed in **~/.local/share/ralph/** with dedicated directories for each installed version underneath. To identify the currently used version of the Ralph CLI, the symlink **~/.local/share/ralph/current/** points to the version folder to use.

The current version of the Ralph CLI is made available by creating a symlink to the users local binaries.

```
ln -sfn ~/.local/share/ralph/current/ralph.sh ~/.local/bin/ralph
```

# Dependencies

The install script requires the following tools:

- **curl** or **wget** - for downloading files
- **jq** - for parsing JSON responses from the GitHub API

If these dependencies are not found on your system, the installer will automatically attempt to install them using your system's package manager.

## Supported Package Managers

| Package Manager | System |
|:----------------|:-------|
| apt-get | Debian, Ubuntu |
| dnf | Fedora, RHEL 8+ |
| yum | CentOS, RHEL 7 |
| pacman | Arch Linux |
| apk | Alpine Linux |
| zypper | openSUSE |
| brew | macOS |

If your package manager is not supported, you will need to install the dependencies manually before running the installer.
