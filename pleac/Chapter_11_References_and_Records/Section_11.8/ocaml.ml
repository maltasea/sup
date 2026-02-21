
(* There is no need to use references just to have a function that
   calls a method. Either write a lambda: *)

let mref = fun x y z -> obj#meth x y z

(* Or, just refer to the method directly: *)

let mref = obj#meth

(* Later... *)

let () = mref "args" "go" "here"

