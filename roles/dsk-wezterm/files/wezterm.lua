local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- GNOME draws no title bar for Wayland clients, so WezTerm paints an extra bar of its own above the tabs that also pushes the window below the panel; through XWayland GNOME draws its normal title bar and handles move, maximize and tiling
config.enable_wayland = false
config.window_background_opacity = 0.85
config.color_scheme = 'Tokyo Night'
config.use_fancy_tab_bar = true
-- Independent of the login shell, which user-workstation resets to /bin/bash on every deploy; no -l, like GNOME Terminal
config.default_prog = { '/usr/bin/zsh' }
-- toast_notification showed no GNOME banner on this desktop, so confirmations go to the tab bar
local function notify(window, message)
  window:set_right_status(message)
  wezterm.time.call_after(3, function() window:set_right_status('') end)
end

local bookmarks_file = wezterm.config_dir .. '/bookmarks'

local function read_bookmarks()
  local bookmarks = {}
  local file = io.open(bookmarks_file, 'r')
  if file then
    for line in file:lines() do
      if line ~= '' then
        table.insert(bookmarks, { label = line })
      end
    end
    file:close()
  end
  return bookmarks
end

wezterm.on('bookmark-add', function(window, pane)
  local cwd = pane:get_current_working_dir()
  if not cwd then
    return
  end
  local path = cwd.file_path
  for _, bookmark in ipairs(read_bookmarks()) do
    if bookmark.label == path then
      notify(window, 'Bookmark already exists: ' .. path)
      return
    end
  end
  local file = io.open(bookmarks_file, 'a')
  file:write(path .. '\n')
  file:close()
  notify(window, 'Bookmark saved: ' .. path)
end)

wezterm.on('bookmark-open', function(window, pane)
  window:perform_action(wezterm.action.InputSelector {
    title = 'Bookmarks',
    fuzzy = true,
    choices = read_bookmarks(),
    action = wezterm.action_callback(function(window, pane, id, label)
      if label then
        window:perform_action(wezterm.action.SpawnCommandInNewTab { cwd = label }, pane)
      end
    end),
  }, pane)
end)

local function change_opacity(window, delta)
  local overrides = window:get_config_overrides() or {}
  local opacity = window:effective_config().window_background_opacity + delta
  overrides.window_background_opacity = math.floor(math.max(0.1, math.min(1.0, opacity)) * 100 + 0.5) / 100
  window:set_config_overrides(overrides)
end

wezterm.on('opacity-increase', function(window) change_opacity(window, 0.05) end)
wezterm.on('opacity-decrease', function(window) change_opacity(window, -0.05) end)

config.keys = {
  { key = 'V', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
  { key = 'H', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.SplitVertical{ domain = 'CurrentPaneDomain' } },
  { key = 'W', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.CloseCurrentPane{ confirm = true } },

  { key = 'LeftArrow',  mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'DownArrow',  mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Down' },

  { key = 'T', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'PageUp',   mods = 'CTRL', action = wezterm.action.ActivateTabRelative(-1) },
  { key = 'PageDown', mods = 'CTRL', action = wezterm.action.ActivateTabRelative(1) },
  { key = 'LeftArrow',  mods = 'ALT|SHIFT', action = wezterm.action.MoveTabRelative(-1) },
  { key = 'RightArrow', mods = 'ALT|SHIFT', action = wezterm.action.MoveTabRelative(1) },

  { key = 'R', mods = 'CTRL|SHIFT', action = wezterm.action.PromptInputLine {
      description = 'Enter a new name for this tab:',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    }
  },

  { key = 'B', mods = 'CTRL|SHIFT', action = wezterm.action.EmitEvent 'bookmark-add' },
  { key = 'O', mods = 'CTRL|SHIFT', action = wezterm.action.EmitEvent 'bookmark-open' },

  { key = 'UpArrow',   mods = 'ALT|SHIFT', action = wezterm.action.EmitEvent 'opacity-increase' },
  { key = 'DownArrow', mods = 'ALT|SHIFT', action = wezterm.action.EmitEvent 'opacity-decrease' },

  { key = 'F1', action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|KEY_ASSIGNMENTS' } },
  { key = 'F1', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnCommandInNewTab { args = { 'less', wezterm.config_dir .. '/HELP.md' } } },
}

return config
