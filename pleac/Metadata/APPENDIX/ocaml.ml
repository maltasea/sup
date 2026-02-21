
open Printf

let sort_ l = List.sort compare l

let rec uniq = function
  | [] -> []
  | e::l -> if List.mem e l then uniq l else e :: uniq l

let rec filter_some = function
  | [] -> []
  | Some e :: l -> e :: filter_some l
  | None :: l -> filter_some l

let rec all_assoc e = function
  | [] -> []
  | (e',v) :: l when e=e' -> v :: all_assoc e l
  | _ :: l -> all_assoc e l

(* fold_left alike. note that it is tail recursive *)
let rec fold_lines f init chan =
  match
    try Some (input_line chan)
    with End_of_file -> None
  with
  | Some line -> fold_lines f (f init line) chan
  | None -> init

let iter_lines f chan = fold_lines (fun _ line -> f line) () chan  
let readlines chan = List.rev (fold_lines (fun l e -> e::l) [] chan)
;;
