# setadb

[中文](https://github.com/huanfeng/setadb/blob/main/README.md)|[English](https://github.com/huanfeng/setadb/blob/main/README.en.md)

A script to easily set the ADB device environment variable

Works by modifying the `ANDROID_SERIAL` variable

Supports Windows CMD/PowerShell and bash/zsh on Linux/macOS

## Installation

### Windows - Scoop (recommended)

```powershell
scoop bucket add huanfeng https://github.com/huanfeng/scoop-bucket
scoop install huanfeng/setadb
```

After installing:

* **CMD**: just run `setadb`
* **PowerShell**: run this once, then plain `setadb` works

  ```powershell
  & "$(scoop prefix setadb)\install-profile.ps1"
  ```

  It also works without that - you just have to spell out `setadb.ps1` every
  time. See [why](#why-powershell-needs-an-extra-step) below.

### Windows - manual

* Add this directory to `PATH`, or copy the scripts into a directory already on `PATH`
* **CMD**: run `setadb`
* **PowerShell**: run `setadb.ps1`, or run `.\install-profile.ps1` once and then use `setadb`

### Linux / macOS

On Linux the script **must** be loaded with `source`. It has to modify the
environment of **your current shell**, and a normally executed script runs in a
child process - once that process exits, everything it set is gone with it.

The recommended way is to load `setadb.sh` from your shell config, which gives
you a `setadb` function:

```bash
# bash
echo 'source "/path/to/setadb.sh"' >> ~/.bashrc && source ~/.bashrc

# zsh
echo 'source "/path/to/setadb.sh"' >> ~/.zshrc && source ~/.zshrc
```

After that, just run `setadb`.

For one-off use without touching your config:

```bash
source /path/to/setadb.sh && setadb
```

Forgot the setup command? Run `setadb --install` to print ready-to-paste lines.
Running `./setadb` or `./setadb.sh` directly prints a loud hint too, rather than
silently doing nothing.

## Usage

Without arguments it lists the connected devices; pick one by index. The device
currently in effect is marked with `*`:

```
ADB devices
-------------------
  0. [Clear]
  1. [2dd1deb9] device
* 2. [192.168.5.67:5555] device
-------------------
Please select:
```

You can also pass an argument to skip the menu:

| Command | Description |
| --- | --- |
| `setadb` | Show the menu and select interactively |
| `setadb 1` | Select menu entry 1 directly |
| `setadb 0` | Clear (index 0 is always Clear) |
| `setadb clear` / `setadb -c` | Clear |
| `setadb 2dd1deb9` | Set the given serial directly |
| `setadb list` / `setadb -l` | List devices without changing anything |
| `setadb -s` | Show the current `ANDROID_SERIAL` |
| `setadb -h` | Show help |

The arguments are identical on all three platforms.

## Why PowerShell needs an extra step

When you type `setadb` in PowerShell, lookup follows `PATHEXT`, where **`.BAT`
ranks above `.PS1`** - so `setadb.bat` is what actually runs. PowerShell runs a
`.bat` in a **new cmd.exe process**, so the variable is set in a process that is
about to exit and the current PowerShell session is unaffected.

The nasty part is that this fails *silently* - it looks like it worked. So
`setadb.bat` detects the situation and says so explicitly:

```
[setadb] WARNING: this cmd.exe exits immediately, so the setting is lost.
```

The fix is to define a **function**: functions outrank every external command in
PowerShell's lookup order, so `setadb` reliably resolves to `setadb.ps1`. That is
all `install-profile.ps1` does (safe to re-run; `-Uninstall` removes it).

For the same reason, `setadb` on Linux is a shell function too.

## Files

| File | Purpose |
| --- | --- |
| `setadb.bat` | Windows CMD version |
| `setadb.ps1` | Windows PowerShell version |
| `install-profile.ps1` | Writes the `setadb` function into your PowerShell `$PROFILE` |
| `setadb.sh` | Linux/macOS version, `source` it to define the `setadb` function |
| `setadb` | Compatibility entry for the old `source setadb`, loads `setadb.sh` |

> `.gitattributes` forces CRLF for `.bat`/`.ps1`. This is not a style choice:
> CMD locates batch labels by byte offset, so a `.bat` with LF endings makes
> every `GOTO`/`CALL` in it jump to the wrong line - a spectacularly hard bug
> to track down.

## Releasing (maintainers)

Pushing a `v*` tag triggers the release workflow: verify line endings -> build
the zip -> publish the GitHub Release -> send a `repository_dispatch` to
`huanfeng/scoop-bucket` so the Scoop manifest updates itself.

Before the first release, copy `.github/scoop-bucket-manifest.json` to
`scoop-bucket/bucket/setadb.json`. The bucket's update script only overwrites
`version`/`url`/`hash` and preserves every other field, so `env_add_path` and
`notes` have to exist up front in order to survive later updates.
