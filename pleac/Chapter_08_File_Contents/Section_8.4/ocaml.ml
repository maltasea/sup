
let lines = ref []
let () =
  try
    while true do
      lines := input_line chan :: !lines
    done
  with End_of_file -> ()
let () =
  List.iter
    (fun line ->
       (* do something with line *)
       ())
    !lines

