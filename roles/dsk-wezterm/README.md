# WezTerm

Custom Infinito.Nexus role (core 17.0.0 or later): installs [WezTerm](https://github.com/wezterm/wezterm) on Pacman-based workstations through core's package batch and deploys `files/wezterm.lua` to `~/.config/wezterm/wezterm.lua` of the workstation user.

`files/wezterm.lua` and `files/HELP.md` are the source of truth. Every deploy overwrites both in `~/.config/wezterm/`, so change them here.

[`files/HELP.md`](files/HELP.md) lists every key binding and window gesture; `Ctrl+Shift+F1` opens it in a new tab.

WezTerm always starts `/usr/bin/zsh` as a non-login shell, like GNOME Terminal does, whatever login shell `/etc/passwd` holds. Windows have no title bar: GNOME gives Wayland clients no frame, so any other `window_decorations` value makes WezTerm draw a second bar above the tabs that also pushes the window below the panel.

Folder bookmarks live in `~/.config/wezterm/bookmarks`. The role does not manage that file, so deploys keep it.

## Activate

Core only discovers roles under its own `roles/` directory. Its `make roles-pull` places only `web-app-cst-*` roles, so link this one into the core checkout you deploy from and keep the link out of that checkout's git:

```bash
ln -s "$(pkgmgr path terminal)/roles/dsk-wezterm" roles/dsk-wezterm
echo roles/dsk-wezterm >> "$(git rev-parse --git-path info/exclude)"
```

Core's lints apply to this role like to an in-tree one: run core's full `make test` with the link in place before the first deploy and after every change to the role.

Add the host to the role's group in the inventory:

```yaml
all:
  children:
    dsk-wezterm:
      hosts:
        <host>:
```

## Deploy

From the core checkout, deploying only this role:

```bash
export PYTHONPATH="$PWD"
INV="$(pkgmgr path computer-inventory)"
HOST=<host>
/opt/venvs/infinito/bin/infinito administration deploy dedicated "${INV}/pcs.yml" -l "${HOST}" -p "${INV}/.pass/${HOST}.txt" --id dsk-wezterm
```

## Author

Kevin Veen-Birkenbach <kevin@veen.world>
