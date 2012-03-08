VERSION = 1.0.1

.PHONY: default
default: all opt

.PHONY: all opt install uninstall clean release doc VERSION
all: VERSION
	ocamlfind ocamlc -c -g dum.mli -package easy-format
	ocamlfind ocamlc -c -g dum.ml -package easy-format
	ocamlfind ocamlc -a -g -o dum.cma dum.cmo -package easy-format
	touch done-all
opt: VERSION
	ocamlfind ocamlc -c -g dum.mli -package easy-format
	ocamlfind ocamlopt -c -g dum.ml -package easy-format
	ocamlfind ocamlopt -a -g -o dum.cmxa dum.cmx -package easy-format
	touch done-opt
install: META
	ocamlfind install dum META dum.mli dum.cmi \
		`test -f done-all && echo dum.cma || :`\
		`test -f done-opt && echo dum.cmx dum.cmxa dum.o dum.a || :`
uninstall:
	ocamlfind remove dum

doc:
	mkdir -p doc/html
	ocamlfind ocamldoc -d doc/html -package easy-format dum.mli -html

clean:
	rm -f *.cm[aiox] *.cmxa *.a *.o *.annot *.opt *.run *~ \
		done-all done-opt
	rm -rf doc

VERSION:
	echo "$(VERSION)" > VERSION

META:
	sed -e 's:@VERSION@:$(VERSION):' META.in > META
