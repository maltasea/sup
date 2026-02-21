
let () =
  let address = recsize * recno in
  seek_in fh address;
  really_input fh buffer 0 recsize

(*-----------------------------*)

let () =
  let address = recsize * (recno - 1) in
  (* ... *)
  ()

