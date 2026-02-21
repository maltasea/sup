
#load "unix.cma";;

let () =
  let (readme, writeme) = Unix.open_process program in
  output_string writeme "here's your input\n";
  close_out writeme;
  let output = input_line readme in
  ignore (Unix.close_process (readme, writeme))

