# vim-auto-indent-settings
Plugin for the Vim editor. Similar to [vim-sleuth](https://github.com/tpope/vim-sleuth) or [detectindent](https://github.com/ciaranm/detectindent). Automatically scans the opened buffer for existing indentation and sets the local settings for `tabstop`, `softtabstop`, `shiftwidth` and `expandtab` accordingly.

Key differences to those other two plugins:
1. This plugin will honour modelines. Someone put them there for a reason and they will always be more accurate than some basic heuristic.
2. No messing with `tabstop` when files are indented with hard tabs. You set your `tabstop` in your .vimrc and that is the value that shall be used for tabs. When files contain both tabs *and* spaces, however, `tabstop` will be set to fit the existing spaces.
3. When a file contains both tabs *and* spaces for indentation, but one is used predominately, `expandtab` will be set to favour the already dominating style. Should both styles be found evenly, the users `expandtab` setting (or the default `off`) will be used.
4. No looking through other files when opening a completely new file. tpope might consider that a feature, *I* consider that annoying. I set defaults in my .vimrc and I want them to be used (or I run formatter over my files anyway).
