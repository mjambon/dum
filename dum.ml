
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


open Printf

(* Pointers already visited are stored in a hash-table, where
   comparisons are done using physical equality. *)

module H = Hashtbl.Make(
  struct 
    type t = Obj.t 
    let equal = (==) 
    let hash r = Hashtbl.hash (Obj.obj r : int)
  end)

type node =
    Int of int
  | Cycle of address option ref
  | Block of block

and block_value =
    String of string
  | Float of float
  | Array of node list
  | Float_array of float array
  | Tag of (int * node list)
  | Object of (int * node list)
  | Closure of node list
  | Lazy of node (* a closure *)
  | Forward of node
  | Opaque of string (* not representable *)
  | List of node list (* anything that could be a non-empty list *)

and address = int

and block = {
  mutable address : address option ref;
  mutable show_address : bool;
  node_value : block_value lazy_t;
}

let create_node_table () = 
  let counter = ref 0 in
  counter, (H.create 257 : block H.t)

let get (_, tbl) r = 
  try 
    let x = H.find tbl r in
    x.show_address <- true;
    Some x.address
  with Not_found -> 
    None

let add (counter, tbl) r lz =
  assert (not (H.mem tbl r));
  let x = {
    address = ref None;
    show_address = false;
    node_value = lz
  } in
  H.add tbl r x;
  x


(* Don't use an array here.
   (unless you make sure it's not created as a double array)
*)
let get_fields r n =
  let l = ref [] in
  for i = n - 1 downto 0 do
    l := Obj.field r i :: !l
  done;
  !l


let is_list tbl r =
  let rec is_list tbl r =
    if Obj.is_int r then
      r = Obj.repr 0 (* [] *)
    else
      let s = Obj.size r and t = Obj.tag r in
      t = 0 && s = 2 && not (H.mem tbl r) &&
	  (H.add tbl r ();
	   let tail = Obj.field r 1 in
	   is_list tbl tail)
  in
  let b = is_list tbl r in
  H.clear tbl;
  b

    
let rec get_list accu r =
  if Obj.is_int r then
    List.rev accu
  else 
    let h = Obj.field r 0 in
    get_list (h :: accu) (Obj.field r 1)


let map f l = List.rev (List.rev_map f l)


let default_lim = ref 100
let default_show_lazy = ref false

exception Too_big

let rev_iter f l = List.iter f (List.rev l)


(* Set the show_address field *)
let rec force = function
    Int _ -> ()
  | Cycle _ -> ()
  | Block b ->
      match Lazy.force b.node_value with
	  String _ -> ()
	| Float _ -> ()
	| Array l -> List.iter force l
	| Float_array _ -> ()
	| Tag (t, l) -> List.iter force l
	| Object (id, l) -> List.iter force l
	| Closure l -> List.iter force l
	| Lazy x -> force x
	| Forward x -> force x
	| Opaque _ -> ()
	| List l -> List.iter force l

(* Set the actual addresses, using left-to-right numbering *)
let set_addresses x =
  let counter = ref 0 in

  let rec force = function
      Int _ -> ()
    | Cycle _ -> ()
    | Block b ->
	if b.show_address then (
	  b.address := Some !counter;
	  incr counter
	);
	match Lazy.force b.node_value with
	    String s -> ()
	  | Float _ -> ()
	  | Array l -> List.iter force l
	  | Float_array _ -> ()
	  | Tag (t, l) -> List.iter force l
	  | Object (id, l) -> List.iter force l
	  | Closure l -> List.iter force l
	  | Lazy x -> force x
	  | Forward x -> force x
	  | Opaque _ -> ()
	  | List l -> List.iter force l
  in

  force x



let dump_tree ?show_lazy ?lim x =

  let lim = max 1 (
    match lim with
	None -> !default_lim
      | Some n -> n
  ) in

  let show_lazy =
    match show_lazy with
	None -> !default_show_lazy
      | Some b -> b
  in

  let tbl = create_node_table () in
  let tbl2 = H.create 10 in
  let size = ref 0 in

  let rec dump r =
    incr size;
    if !size > lim then
      raise Too_big
    else
      if Obj.is_int r then
	Int (Obj.obj r : int)
      else 
	dump_block r

  and dump_block r =
    match get tbl r with
	Some addr -> Cycle addr
      | None ->
	  let lz = lazy (
	    let saved_size = !size in
	    try
	      dump_shared_block r
	    with Too_big ->
	      size := saved_size;
	      Opaque "..."
	  ) in
	  Block (add tbl r lz)

  and dump_shared_block r =
    let s = Obj.size r and t = Obj.tag r in
    if is_list tbl2 r then
      let fields = get_list [] r in
      List (map dump fields)
    else if t = 0 then
      let fields = get_fields r s in
      Array (map dump fields)
    else if t = Obj.double_array_tag then
      Float_array (Obj.obj r : float array)
    else if t = Obj.lazy_tag then
      if show_lazy then (
	assert (s = 1);
	Lazy (dump (Obj.field r 0))
      )
      else
	Opaque "lazy"
    else if t = Obj.forward_tag then (
      if show_lazy then (
	assert (Lazy.lazy_is_val (Obj.obj r));
	Forward (dump (Obj.repr (Lazy.force_val (Obj.obj r))))
      )
      else
	Opaque "forward"
    )
    else if t = Obj.closure_tag then
      let fields = get_fields r s in
      assert (s >= 1);
      Closure (map dump (List.tl fields))

    else if t = Obj.object_tag then
      let fields = get_fields r s in
      assert (s >= 2);
      let id = 
	let r = Obj.repr (List.nth fields 1) in
	assert (Obj.is_int r);
	(Obj.obj r : int)
      in
      let slots = map dump (List.tl (List.tl fields)) in
      (* No information on decoding the class (first field).
	 So just print out the ID and the slots. *)
      Object (id, slots)
	
    else if t = Obj.infix_tag then
      Opaque "infix"
    else if t < Obj.no_scan_tag then
      let fields = get_fields r s in
      Tag (t, map dump fields)
    else if t = Obj.string_tag then (
      let str = (Obj.obj r : string) in
      size := !size + (String.length str / 8);
      if !size > lim then
	raise Too_big
      else
	String str
    )
    else if t = Obj.double_tag then
      Float (Obj.obj r : float)
    else if t = Obj.abstract_tag then
      Opaque "abstract"
    else if t = Obj.custom_tag then
      Opaque "custom"
    else if t = Obj.final_tag then
      Opaque "final"
    else if t = Obj.out_of_heap_tag then
      Opaque "out of heap"
    else
      Opaque ("unknown tag " ^ string_of_int t)
	
  in
  
  let result = dump (Obj.repr x) in
  force result;
  set_addresses result;
  result



module E = Easy_format


let atom = E.atom

let list = E.list

let tuple = { list with
		E.space_after_opening = false;
		space_before_closing = false }

let label = E.label

let format_float x = E.Atom (string_of_float x, atom)

let rec format = function
    Int i -> E.Atom (string_of_int i, atom)
  | Cycle x ->
      (match !x with
	   None -> assert false
	 | Some n -> E.Atom (sprintf "#%i" n, atom))
  | Block b ->
      let node =
	match Lazy.force b.node_value with
	    String s -> E.Atom (sprintf "%S" s, atom)
	  | Float f -> format_float f

	  | Array a -> 
	      let l = map format a in
	      E.List (("(", "", ")", tuple), l)

	  | Float_array a ->
	      let l = 
		Array.to_list (Array.map format_float a) in
	      E.List (("[|", "", "|]", list), l)
			
	  | Tag (t, a) -> 
	      let l = map format a in
	      E.Label (
		(E.Atom (sprintf "tag%i" t, atom), label),
		E.List (("(", "", ")", tuple), l)
	      )

	  | Object (id, a) ->
	      let l = map format a in
	      E.Label (
		(E.Atom (sprintf "object%i" id, atom), label),
		E.List (("(", "", ")", tuple), l)
	      )

	  | Closure a ->
	      let l = map format a in
	      E.Label (
		(E.Atom ("closure", atom), label),
		E.List (("(", "", ")", tuple), l)
	      )

	  | Lazy x ->
	      let l = [ format x ] in
	      E.Label (
		(E.Atom ("lazy", atom), label),
		E.List (("(", "", ")", tuple), l)
	      )

	  | Forward x ->
	      let l = [ format x ] in
	      E.Label (
		(E.Atom ("forward", atom), label),
		E.List (("(", "", ")", tuple), l)
	      )

	  | Opaque s ->
	      E.Atom (sprintf "<%s>" s, atom)

	  | List nodes ->
	      let l = map format nodes in
	      E.List (("[", "", "]", list), l)
      in
      if b.show_address then
	let n =
	  match !(b.address) with
	      None -> assert false
	    | Some n -> n
	in
	E.Label (
	  (E.Atom (sprintf "#%i:" n, atom), label),
	  node
	)
      else
	node


let to_eformat ?show_lazy ?lim x = format (dump_tree ?show_lazy ?lim x)

let to_string ?show_lazy ?lim x = 
  E.Pretty.to_string (to_eformat ?show_lazy ?lim x)
let to_stdout ?show_lazy ?lim x =
  E.Pretty.to_stdout (to_eformat ?show_lazy ?lim x)
let to_stderr ?show_lazy ?lim x =
  E.Pretty.to_stderr (to_eformat ?show_lazy ?lim x)
let to_channel ?show_lazy ?lim oc x =
  E.Pretty.to_channel oc (to_eformat ?show_lazy ?lim x)
let to_formatter ?show_lazy ?lim fmt x =
  E.Pretty.to_formatter fmt (to_eformat ?show_lazy ?lim x)
let to_buffer ?show_lazy ?lim buf x =
  E.Pretty.to_buffer buf (to_eformat ?show_lazy ?lim x)

let p = to_string
