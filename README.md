# Cmder-powerline-prompt

This is a custom prompt for [Clink](https://github.com/chrisant996/clink) and/or [Cmder](http://cmder.net/) (the alternative console emulator for Windows). There's also a [PowerShell version](https://github.com/AmrEldib/cmder-powershell-powerline-prompt) of this prompt.  
It looks like this:  
![screenshot](screenshot.png)

The prompt has multiple segments:  
- Folder: in blue. Displays the folder name, or full path. Replaces the user's home folder with a tilde (~).  
- npm: in teal. If it detects an npm package, it displays the package name and version number.  
- Git: in various colors. If it detects a Git repo, it displays the branch name. Green if no changes, yellow if changes, red for conflicts, magenta for staged changes, and cyan for commits ahead/behind upstream.

In the screenshot, [Fira Code](https://github.com/tonsky/FiraCode) font is used.  

The look is inspired by [Powerline for Vim](https://github.com/powerline/powerline), and [Zsh's theme agnoster](https://github.com/agnoster/agnoster-zsh-theme).

# Requirements

Download the [AnonymousPro font](https://github.com/powerline/fonts/tree/master/AnonymousPro).  
You'll be able to use any font in Cmder, but this font contains the symbols included in the prompt.

## Font

To use another font and still show symbols correctly:

* Go to Cmder Settings > Main
* Choose Main console font to be what you prefer
* Choose _Alternative font_ to be _Anonymice Powerline_
* Modify the value of _Unicode ranges_ to add: `E0A0; E0B0;`
  * for extra symbols set in `_powerline_config.lua` (like npm logo for node module or git project for smart path resolving) set the _Alternative font_ to one of your choosing.
    ![screenshot](screenshot_fonts.png)
  * The [Icomoon](https://icomoon.io/) includes npm and git symbols. You might find [nerd-fonts](https://github.com/ryanoasis/nerd-fonts) helpful as well.  
* Save Settings

# Setup

Download the `.lua` files, and place it in `%CMDER_ROOT%/config` folder.  
Restart Cmder or Clink to load the prompt.

**Alternatively**, if you want to maintain link with the original repo, you can clone this repo into any folder.  
`git clone https://github.com/chrisant996/cmder-powerline-prompt.git optional-local-folder-name`  
then create a symbolic link from the `%CMDER_ROOT%/config` folder to the `.lua` file.

```bat
cd %CMDER_ROOT%/config  
mklink /H powerline_core.lua <git-repo-folder-name>/powerline_core.lua
mklink /H powerline_prompt.lua <git-repo-folder-name>/powerline_prompt.lua
```

To add Git prompt, add the Git file

```bat
mklink /H powerline_git.lua <git-repo-folder-name>/powerline_git.lua
```

To add Configurations, create a file named `_powerline_config.lua` that is a copy of the file `_powerline_config.lua.sample`

To add symbolic links across drives (from C drive pointing to D drive, for example), use PowerShell instead of `mklink`.  
```powershell
new-item -path powerline_core.lua -itemtype symboliclink -value <path to repo folder>\cmder-powerline-prompt\powerline_core.lua
```

## Configuration

Config file is `_powerline_config.lua`. This file isn't created by default to avoid overwrite on future updates.  
A sample config file is included: `_powerline_config.lua.sample`

See the file `_powerline_config.lua.sample` for full list and details of configurations.  

# Helpful info for customizing Cmder

## Links

[Cmder Source Code and README](https://github.com/cmderdev/cmder)  
[What is Clink](https://chrisant996.github.io/clink/)  
[Clink Lua API](https://chrisant996.github.io/clink/clink.html#lua-api)  
[ANSI Color Sequence](http://ascii-table.com/ansi-escape-sequences.php)

## Cmder Configurations

Cmder configurations is stored in `%CMDER_ROOT%\config\`  
You can add files to be loaded during startup in either of these folders  
 `%CMDER_ROOT%\config\profile.d`  
 `%CMDER_ROOT%\config`  
Add a `.ps1` file to be loaded for Powershell shells  
Add a `.bat` or `.cmd` files to be loaded for Windows Command shells  
Add a `.sh` file to be loaded for Bash shells  
User-specific configurations should go into files named `user-profile` with extensions `ps1`, `cmd`/`bat`, or `sh`.

## Clink Prompt

Drop .lua files into the `%CMDER_ROOT%\Config` folder to customize the prompt.

The file `%CMDER_ROOT%\vendor\clink.lua` sets the command prompt. See the function `set_prompt_filter`.  
See [Customising The Prompt](https://chrisant996.github.io/clink/clink.html#customisingtheprompt) in the Clink documentation for more info about how prompt customisation works.  

# Status & Contributions

This is forked from [AmrEldib/cmder-powerline-prompt](https://github.com/AmrEldib/cmder-powerline-prompt), since that repo appears to have been abandoned.  
This code is provided with the timeless **Works on my Machine** guarantee.  

# Writing an addon  
This prompt uses an addon architecture to allow for additional functionality.  
`powerline_prompt.lua` is a good example for how to write an addon. The code is annotated and explains how to write a new addon.  
To write a new addon, create a new `lua` file in `%CMDER_ROOT%/config`. Start a new tab in Cmder to see the effect of changes.  
