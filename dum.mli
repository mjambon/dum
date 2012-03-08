(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) 2008 Wink Technologies Inc. (contact martin@wink.com)   *)
(*  Copyright (C) 2008 Jean-Christophe Filliatre                          *)
(*  Copyright (C) 2005 Merjis Ltd., Richard W.M. Jones                    *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2.1, with the special exception on linking            *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

(**
   This module dumps arbitrary OCaml values into a human-readable format
   and always terminates.

   Dum was derived from both the Size module and 
   from the Std.dump function of Extlib formerly known as Dumper.

   The output format is not formally defined and is meant only 
   to be inspected by humans. The basic conventions (subject to change)
   are the following:
   - parentheses [(...)] delimit blocks such as tuples or anything equivalent.
   - square brackets [[...]] delimit a chain of blocks that is compatible
     with the structure of a finite list, i.e. [[ 1 2 3 ]] is the same as
     [(1 (2 (3 0)))].
   - angle brackets [<...>] delimit something that is not shown in depth
     for some reason.
   - the number sign [#] followed by a number denotes a reference to a shared
     value, e.g. [#0: (1 (2 #0))] can be obtained with 
     [let rec l = 1 :: 2 :: l in Dum.p l].
   - the regular OCaml array notation [[|...|]] is reserved to unboxed
     arrays of floats.

   The rest is self-explanatory.
*)


val default_lim : int ref
  (**
    Default limit of the number of nodes to dump: 100.
    Strings account for one eighth of their length.
  *)

val default_show_lazy : bool ref
  (**
    Whether to inspect lazy values. This is false by default.

    Warning: this relies on unofficially documented material of the
    standard distribution (file lazy.ml) and lazy values altogether
    are an experimental feature of OCaml.

    This functionality may disappear in the future.
  *)

val to_eformat : ?show_lazy:bool -> ?lim:int -> 'a -> Easy_format.t
  (**
     Convert any OCaml value into an Easy_format.t tree.
  *)

val to_string : ?show_lazy:bool -> ?lim:int -> 'a -> string
val p : ?show_lazy:bool -> ?lim:int -> 'a -> string
  (**
     Dump to a string. [Dum.to_string] and [Dum.p] are equivalent.
  *)

val to_stdout : ?show_lazy:bool -> ?lim:int -> 'a -> unit
  (** Dump to [stdout]. *)

val to_stderr : ?show_lazy:bool -> ?lim:int -> 'a -> unit
  (** Dump to [stderr]. *)

val to_channel : ?show_lazy:bool -> ?lim:int -> out_channel -> 'a -> unit
  (** Dump to the specified [out_channel] *)

val to_formatter :
  ?show_lazy:bool -> ?lim:int -> Format.formatter -> 'a -> unit
  (** Dump to a formatter created by the Format module. *)

val to_buffer : ?show_lazy:bool -> ?lim:int -> Buffer.t -> 'a -> unit
  (** Dump to a buffer. *)
