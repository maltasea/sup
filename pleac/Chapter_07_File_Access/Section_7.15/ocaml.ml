
#load "unix.cma";;

(* OCaml does not expose the FIONREAD ioctl call. It's better to use
   non-blocking reads anyway. There is the following function in
   Pervasives which gives you the length of an input channel, but it
   works by doing a seek so it only works on regular files: *)

let () =
  let length = in_channel_length in_channel in
  (* ... *)
  ()

