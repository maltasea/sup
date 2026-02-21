
#load "str.cma";;

let main data =
  List.iter
    (fun line ->
       (* process the line *)
       ())
    (Str.split (Str.regexp "\n") data)

let () = main "\
your data goes here
"

