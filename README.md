# `l3sys-query`: System queries for LaTeX using Lua

Release 2024-03-15

## Overview

The `l3sys-query` script provides a method for TeX runs to obtain system
information _via_ shell escape to Lua. The facilities are more limited than the
similar Java script `texosquery`, but since it uses Lua, `l3sys-query` can be
used 'out of the box' with any install TeX system. The script is written taking
account of TeX Live security requirement; it is therefore suitable for use with
restricted shell escape, the standard setting when installing a TeX system.

The supported queries are
- `ls`: Directory listing supporting a range of options
- `pwd`: Obtaining details of the current working directory

## Issues

The issue tracker for LaTeX is currently located
[on GitHub](https://github.com/latex3/l3sys-query/issues).

## Development team

This code is developed by [The LaTeX Project](https://latex-project.org).

## License

This project licensed under the same terms as Lua (MIT): see LICENSE or the top
of source files for the legal text.

-----

<p>Copyright (C) 2024 The LaTeX Project <br />
<a href="https://latex-project.org/">https://latex-project.org/</a> <br />
All rights reserved.</p>
