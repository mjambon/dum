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

```
$ opam update
$ opam install dum
```

Usage
-----

We do not recommend the use of this library in production code due to
its reliance on OCaml internals and unsafe memory access.

```ocaml
$ utop -require dum
# Dum.to_stdout (123, "abc", Not_found, [`A; `B 'x']);;
(123 "abc" object-7 () [ 65 (66 120) ])
```

A circular list is printed as follows:

```ocaml
# let rec cyc = 1 :: 2 :: 3 :: cyc;;
val cyc : int list = [1; 2; 3; <cycle>]

utop # Dum.to_stdout cyc;;
#0: (1 (2 (3 #0)))
```

See `dum.mli` for more information.

License
-------

GNU LGPL with exception on static linking, see file LICENSE.
