
let () = Dbm.iter (Dbm.replace output) input

(*-----------------------------*)

let () =
  Dbm.iter
    (fun key value ->
       try
         let existing = Dbm.find output key value in
         (* decide which value to use and replace if necessary *)
         ()
       with Not_found ->
         Dbm.replace output key value)
    input

