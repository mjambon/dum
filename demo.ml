
type t = A of int list | B of int * int | C of t * t

let demo ?lim () =
  let tbl = Hashtbl.create 5 in
  let rec l = 3 :: 4 :: 5 :: l in
  let rec v = C (A [1;2;3], v) in
  Hashtbl.add tbl `A ("abc", `Table (tbl, l));
  Hashtbl.add tbl `B ("xyz", `List (1 :: 2 :: l));
  Hashtbl.add tbl (`C (Some 1.234)) ("C", `Fun (fun () -> ()));
  Hashtbl.add tbl `D ("", `Variant (B (3, 4)));
  let x =
    (object (self)
       method tbl = tbl
     end),
    [| 1.0; 2.0 |],
    { Complex.re = 0.;
      im = 1. },
    (Failure "test"),
    [ true; false ],
    ()
  in
  
  Dum.to_stdout ?lim x;
  print_newline ()

let _ = 
  demo ();
  demo ~lim:10 ();
  demo ~lim:2 ()

