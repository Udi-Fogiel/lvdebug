Visual debugging for LuaTeX
===========================

The LuaTeX package `lua-visual-debug` shows boxes, glues, kerns and penalties in the PDF output.

Usage:

LaTeX:

    \usepackage{lua-visual-debug}

or plain:

    \input lua-visual-debug.sty

or OpTeX:

    \load[lua-visual-debug]



Requirements: The package has only been tested with LuaTeX and
  the formats plain and LaTeX. Other formats might work as well,
  but other engines only show a warning message.


Copyright 2012–2025 Patrick Gundlach (<patrick@gundla.ch>) and others (see Git information)

Package version: 2025-12-29 v1.0

Public repository: <https://github.com/Udi-Fogiel/lvdebug>

Licensed under the MIT license. See the Lua file for details.

The idea is heavily inspired by Hans Hagen's <https://www.pragma-ade.com/articles/art-visi.pdf>


Example output
--------------

<p align="center"><img width="300px" src="https://i.imgur.com/S78jTxb.png"></p>
