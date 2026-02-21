
(* OCaml's Dbm module does not provide any mechanism for a custom
   comparison function. If you need the keys in a particular order
   you can load them into memory and use List.sort, Array.sort, or
   a Set. This may not be practical for very large data sets. *)

