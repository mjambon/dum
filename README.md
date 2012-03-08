Dum
===

Purpose
-------

Inspecting arbitrary OCaml values for debugging or just for fun.

Cycles are detected and an additional limit on the size of the dump is
set by default. It is therefore safe to use for printing out
exceptions in error messages.

Closure fields and object fields are printed.

All the lazy values (forced or not) can be printed but this is optional.
Some forced lazy values will always be printed no matter what.


Installation
------------

After having installed the easy-format library, do:

make
make opt
make install

Or install everything from GODI.


Usage
-----

See HTML documentation.


License
-------

GNU LGPL with exception on static linking, see file LICENSE.
