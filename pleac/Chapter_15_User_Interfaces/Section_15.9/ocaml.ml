
#load "unix.cma";;

let () =
  Unix.set_nonblock Unix.stdin;
  try
    let char = with_cbreak input_char stdin in
    (* input was waiting and it was char *)
    ()
  with Sys_blocked_io ->
    (* no input was waiting *)
    ()

