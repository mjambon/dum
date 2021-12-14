(lang dune 2.9)
(name dum)
(generate_opam_files true)

(maintainers "martin@mjambon.com")
(authors 
  "Martin Jambon"
  "Jean-Christophe Filliatre"
  "Richard W.M. Jones")
(license "LGPL-2.1-or-later WITH OCaml-LGPL-linking-exception")
(source (github dune-universe/dum))

(package
  (name dum)
  (synopsis "Inspect the runtime representation of arbitrary OCaml values")
  (description "Dum is a library for inspecting the runtime representation of
arbitrary OCaml values. Shared or cyclic data are detected
and labelled. This guarantees that printing would always
terminate. This makes it possible to print values such as closures,
objects or exceptions in depth and without risk.")
  (depends
    easy-format))
