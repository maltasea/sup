(* shelm — a simple scripting language interpreter in OCaml *)

(* ============================================================
   Types
   ============================================================ *)

type value =
  | Nil
  | Num of float
  | Str of string
  | Arr of dynarr
  | Dict of (string, value) Hashtbl.t
  | Rex of Pcre.regexp
  | Lambda of string list * expr
  | LambdaSub of string * string
and dynarr = {
  mutable data : value array;
  mutable len : int;
}
and dict_key =
  | DictKeySymbol of string
  | DictKeyExpr of expr
and expr =
  | EString of string
  | ENum of float
  | ENil
  | EVar of string option * string
  | EArrVar of string option * string
  | EDictVar of string option * string
  | EArrayLit of expr list
  | EDictLit of (dict_key * expr) list
  | ERegex of Pcre.regexp
  | ECall of string * expr list
  | ELambda of string list * expr

type global_decl = {
  required: bool;
  has_default: bool;
  default_expr: string option;
}

type node =
  | NGlobalDecl of int * string * global_decl * expr option
  | NSetVar of int * string * expr
  | NGlobalSet of int * string * expr
  | NSetArr of int * string * expr
  | NSetDict of int * string * expr
  | NReturn of int * expr option
  | NIf of int * expr * node list * node list
  | NUnless of int * expr * node list * node list
  | NWhile of int * expr * node list
  | NSwitch of int * expr * (expr * node list) list * node list
  | NSubDef of int * string * string list * node list * bool
  | NAlias of int * string * string
  | NForeach of int * string * string * node list
  | NFori of int * string * string * node list
  | NBreak of int
  | NContinue of int
  | NCall of int * expr

type sub_def = { params: string list; body: node list; recursive: bool }

(* ============================================================
   Helpers
   ============================================================ *)

let to_str = function
  | Nil -> ""
  | Num f ->
    let finite = match classify_float f with FP_nan | FP_infinite -> false | _ -> true in
    let frac, _ = modf f in
    if finite && frac = 0.0 then string_of_int (int_of_float f)
    else string_of_float f
  | Str s -> s
  | Arr _ -> "<array>"
  | Dict _ -> "<dict>"
  | Rex _ -> "<regex>"
  | Lambda _ -> "<function>"
  | LambdaSub _ -> "<function>"

let to_num = function
  | Nil -> 0.0
  | Num f -> f
  | Str s -> (try float_of_string s with Failure _ -> 0.0)
  | Lambda _ -> 0.0
  | LambdaSub _ -> 0.0
  | _ -> 0.0

let is_truthy = function
  | Nil -> false
  | Num f -> f <> 0.0
  | Str "" -> false
  | Str "0" -> false
  | Str _ -> true
  | Arr _ -> true
  | Dict _ -> true
  | Rex _ -> true
  | Lambda _ -> true
  | LambdaSub _ -> true

(* ============================================================
   Global state
   ============================================================ *)

let main_module = "main"
let current_module = ref main_module

let globals : (string, value) Hashtbl.t = Hashtbl.create 64
let global_arrays : (string, value) Hashtbl.t = Hashtbl.create 16
let global_dicts : (string, value) Hashtbl.t = Hashtbl.create 16

let module_vars : (string, (string, value) Hashtbl.t) Hashtbl.t = Hashtbl.create 16
let module_arrays : (string, (string, value) Hashtbl.t) Hashtbl.t = Hashtbl.create 16
let module_dicts : (string, (string, value) Hashtbl.t) Hashtbl.t = Hashtbl.create 16
let module_subs : (string, (string, sub_def) Hashtbl.t) Hashtbl.t = Hashtbl.create 16
let module_dirs : (string, string) Hashtbl.t = Hashtbl.create 16
let loaded_module_paths : (string, bool) Hashtbl.t = Hashtbl.create 32
let module_loading_paths : (string, bool) Hashtbl.t = Hashtbl.create 32
let module_source_paths : (string, string) Hashtbl.t = Hashtbl.create 32
let module_load_stack : string list ref = ref []
let module_var_frames : (string, (string, value) Hashtbl.t list ref) Hashtbl.t = Hashtbl.create 16
let call_stack : string list ref = ref []
let active_calls : (string, int) Hashtbl.t = Hashtbl.create 64
let active_line_no : int option ref = ref None

let builtins : (string, value list -> value) Hashtbl.t = Hashtbl.create 64
let global_decls : (string, global_decl) Hashtbl.t = Hashtbl.create 64
let strict_globals_mode = ref false

let hashtbl_find_opt tbl key =
  try Some (Hashtbl.find tbl key) with Not_found -> None

let string_index_opt s ch =
  try Some (String.index s ch) with Not_found -> None

let string_rindex_opt s ch =
  try Some (String.rindex s ch) with Not_found -> None

let rec list_nth_opt lst n =
  match lst with
  | [] -> None
  | x :: _ when n = 0 -> Some x
  | _ :: tl when n > 0 -> list_nth_opt tl (n - 1)
  | _ -> None

let getenv_opt name =
  try Some (Sys.getenv name) with Not_found -> None

let parse_positive_int_env name default =
  match getenv_opt name with
  | None -> default
  | Some raw ->
    let raw = String.trim raw in
    if raw = "" then default
    else
      try
        let n = int_of_string raw in
        if n > 0 then n else default
      with Failure _ -> default

let parse_positive_int_env_alias preferred legacy default =
  match getenv_opt preferred with
  | Some _ -> parse_positive_int_env preferred default
  | None -> parse_positive_int_env legacy default

let max_call_depth =
  parse_positive_int_env_alias "SHELM_MAX_CALL_DEPTH" "SUP_MAX_CALL_DEPTH" 1024

let max_capture_bytes =
  parse_positive_int_env_alias "SHELM_MAX_CAPTURE_BYTES" "SUP_MAX_CAPTURE_BYTES" (16 * 1024 * 1024)

let dynarr_empty () = { data = [||]; len = 0 }

let dynarr_of_list lst =
  let data = Array.of_list lst in
  { data; len = Array.length data }

let dynarr_to_list arr =
  let rec loop i acc =
    if i < 0 then acc
    else loop (i - 1) (arr.data.(i) :: acc)
  in
  loop (arr.len - 1) []

let dynarr_iter f arr =
  for i = 0 to arr.len - 1 do
    f arr.data.(i)
  done

let dynarr_ensure_capacity arr needed =
  let current = Array.length arr.data in
  if current < needed then begin
    let base = if current = 0 then 4 else current in
    let rec grow cap =
      if cap >= needed then cap else grow (cap * 2)
    in
    let next = grow base in
    let data = Array.make next Nil in
    Array.blit arr.data 0 data 0 arr.len;
    arr.data <- data
  end

let dynarr_push arr v =
  dynarr_ensure_capacity arr (arr.len + 1);
  arr.data.(arr.len) <- v;
  arr.len <- arr.len + 1

let dynarr_get arr idx =
  if idx < 0 || idx >= arr.len then None
  else Some arr.data.(idx)

let dynarr_pop arr =
  if arr.len = 0 then None
  else begin
    let idx = arr.len - 1 in
    let v = arr.data.(idx) in
    arr.data.(idx) <- Nil;
    arr.len <- idx;
    Some v
  end

let split_last lst =
  let rec aux rev_prefix = function
    | [] -> (List.rev rev_prefix, None)
    | [x] -> (List.rev rev_prefix, Some x)
    | x :: xs -> aux (x :: rev_prefix) xs
  in
  aux [] lst

let list_filter_map f lst =
  let rec aux acc = function
    | [] -> List.rev acc
    | x :: xs ->
      match f x with
      | Some y -> aux (y :: acc) xs
      | None -> aux acc xs
  in
  aux [] lst

let starts_with s prefix =
  let slen = String.length s in
  let plen = String.length prefix in
  slen >= plen && String.sub s 0 plen = prefix

let with_line_context msg =
  match !active_line_no with
  | Some line when not (starts_with msg "line ") ->
    Printf.sprintf "line %d: %s" line msg
  | _ -> msg

let is_relative_path path =
  let len = String.length path in
  if len = 0 then true
  else if path.[0] = '/' then false
  else if len > 2 && path.[0] = '\\' && path.[1] = '\\' then false
  else if len > 1 && path.[1] = ':' then false
  else true

let ensure_module_table store module_name =
  match hashtbl_find_opt store module_name with
  | Some tbl -> tbl
  | None ->
    let tbl = Hashtbl.create 16 in
    Hashtbl.replace store module_name tbl;
    tbl

let module_vars_ref module_name = ensure_module_table module_vars module_name
let module_arrays_ref module_name = ensure_module_table module_arrays module_name
let module_dicts_ref module_name = ensure_module_table module_dicts module_name
let module_subs_ref module_name = ensure_module_table module_subs module_name

let module_var_frames_ref module_name =
  match hashtbl_find_opt module_var_frames module_name with
  | Some frames -> frames
  | None ->
    let base = module_vars_ref module_name in
    let frames = ref [base] in
    Hashtbl.replace module_var_frames module_name frames;
    frames

let rec module_var_lookup_in_frames name = function
  | [] -> None
  | frame :: rest ->
    (match hashtbl_find_opt frame name with
    | Some v -> Some v
    | None -> module_var_lookup_in_frames name rest)

let module_var_lookup module_name name =
  let frames = !(module_var_frames_ref module_name) in
  module_var_lookup_in_frames name frames

let module_var_set module_name name value =
  match !(module_var_frames_ref module_name) with
  | frame :: _ -> Hashtbl.replace frame name value
  | [] -> failwith ("no frame for module " ^ module_name)

let module_var_remove_top module_name name =
  match !(module_var_frames_ref module_name) with
  | frame :: _ -> Hashtbl.remove frame name
  | [] -> ()

let module_var_find_top module_name name =
  match !(module_var_frames_ref module_name) with
  | frame :: _ -> hashtbl_find_opt frame name
  | [] -> None

let push_module_var_frame module_name =
  let frames = module_var_frames_ref module_name in
  frames := (Hashtbl.create 16) :: !frames

let pop_module_var_frame module_name =
  let frames = module_var_frames_ref module_name in
  match !frames with
  | _ :: rest when rest <> [] -> frames := rest
  | _ -> ()

let () =
  ignore (module_vars_ref main_module);
  ignore (module_var_frames_ref main_module);
  ignore (module_arrays_ref main_module);
  ignore (module_dicts_ref main_module);
  ignore (module_subs_ref main_module);
  Hashtbl.replace module_dirs main_module "."

(* Forward ref so load builtin can call run_program *)
let run_lines_ref : (string list -> unit) ref = ref (fun _ -> ())
let call_depth = ref 0
let returning = ref false
let breaking = ref false
let continuing = ref false
let loop_depth = ref 0

(* ============================================================
   Precompiled regexes
   ============================================================ *)

let re_set_var =
  Str.regexp {|^\(set\|def\|let\)[ 	]+\$\([^ 	=]+\)[ 	]*=[ 	]*\(.*\)$|}
let re_set_arr =
  Str.regexp {|^\(set\|def\|let\)[ 	]+@\([^ 	=]+\)[ 	]*=[ 	]*\(.*\)$|}
let re_set_dict =
  Str.regexp {|^\(set\|def\|let\)[ 	]+%\([^ 	=]+\)[ 	]*=[ 	]*\(.*\)$|}
let re_global_set =
  Str.regexp {|^\$\([^ 	=]+\)[ 	]*=[ 	]*\(.*\)$|}
let re_global_decl =
  Str.regexp {|^global[ 	]+\$\([^ 	]+\)\([ 	]+\(.*\)\)?[ 	]*$|}
let re_if = Str.regexp {|^if[ 	]+\(.*\)$|}
let re_when = Str.regexp {|^when[ 	]+\(.*\)$|}
let re_unless = Str.regexp {|^unless[ 	]+\(.*\)$|}
let re_while = Str.regexp {|^while[ 	]+\(.*\)$|}
let re_switch = Str.regexp {|^switch[ 	]+\(.*\)$|}
let re_case = Str.regexp {|^case[ 	]+\(.*\)$|}
let re_sub_def =
  Str.regexp {|^\(rec\|defun\)[ 	]+\([^ 	(]+\)[ 	]*(\([^)]*\))[ 	]*$|}
let re_alias =
  Str.regexp
    {|^alias[ 	]+\([^ 	=]+\)[ 	]*=[ 	]*\([^ 	]+\)[ 	]*$|}
let re_foreach =
  Str.regexp
    {|^foreach[ 	]+\$\([^ 	]+\)[ 	]+@\([^ 	]+\)[ 	]*$|}
let re_fori =
  Str.regexp
    {|^fori[ 	]+\$\([^ 	]+\)[ 	]+@\([^ 	]+\)[ 	]*$|}
let re_return = Str.regexp {|^return[ 	]*(\(.*\))[ 	]*$|}
let re_bare_call = Str.regexp {|^[^ 	(][^ 	(]*[ 	]*(|}
let re_number = Str.regexp {|^-?[0-9]+\(\.[0-9]+\)?$|}
let re_regex_lit = Str.regexp {|^#"\(.*\)"$|}
let re_end = Str.regexp {|^end\([ 	].*\)?$|}
let re_else = Str.regexp {|^else\([ 	].*\)?$|}
let re_global_default = Str.regexp {|^default[ 	]*(\(.*\))[ 	]*$|}

let re_light_defun_prefix =
  Str.regexp {|^defun[ 	]+\([A-Za-z_][A-Za-z0-9_]*\)\(.*\)$|}
let re_light_defun_parens =
  Str.regexp {|^[ 	]*(\([^)]*\))[ 	]+do$|}
let re_light_defun_brackets =
  Str.regexp {|^[ 	]*\[\([^]]*\)\][ 	]+do$|}
let re_light_defun_no_params =
  Str.regexp {|^[ 	]+do$|}
let re_light_defun_bare_params =
  Str.regexp {|^[ 	]+\(.*[^ 	]\)[ 	]+do$|}
let re_light_if_then = Str.regexp {|^if[ 	]+\(.*\)[ 	]+then$|}
let re_light_elif_then = Str.regexp {|^elif[ 	]+\(.*\)[ 	]+then$|}
let re_light_while_do = Str.regexp {|^while[ 	]+\(.*\)[ 	]+do$|}
let re_light_foreach_do =
  Str.regexp {|^foreach[ 	]+\([A-Za-z_][A-Za-z0-9_]*\)[ 	]+in[ 	]+\(.*\)[ 	]+do$|}
let re_light_let_def =
  Str.regexp {|^\(let\|def\)[ 	]+\([A-Za-z_][A-Za-z0-9_]*\)[ 	]*=[ 	]*\(.*\)$|}
let re_light_assign =
  Str.regexp {|^\([A-Za-z_][A-Za-z0-9_]*\)[ 	]*=[ 	]*\(.*\)$|}
let re_light_index_assign =
  Str.regexp {|^\([A-Za-z_][A-Za-z0-9_]*\)[ 	]*\[[ 	]*\(.*\)[ 	]*\][ 	]*=[ 	]*\(.*\)$|}
let re_light_bare_call =
  Str.regexp {|^\([A-Za-z_][A-Za-z0-9_]*\)[ 	]+\(.+\)$|}
let re_light_call_no_space =
  Str.regexp {|^\([A-Za-z_][A-Za-z0-9_]*\)(|}
let re_light_return =
  Str.regexp {|^return\([ 	]+\(.*\)\)?$|}
let re_light_fun_assign_let_def =
  Str.regexp
    {|^\(let\|def\)[ 	]+\([A-Za-z_][A-Za-z0-9_]*\)[ 	]*=[ 	]*fun[ 	]*\[\([^]]*\)\][ 	]+do$|}
let re_light_fun_assign =
  Str.regexp
    {|^\([A-Za-z_][A-Za-z0-9_]*\)[ 	]*=[ 	]*fun[ 	]*\[\([^]]*\)\][ 	]+do$|}

let re_matches rex s = Str.string_match rex s 0

let is_blank_or_comment s =
  let trimmed = String.trim s in
  trimmed = "" || (String.length trimmed > 0 && trimmed.[0] = '#')

let is_end s =
  re_matches re_end s

let is_else s =
  re_matches re_else s

let is_ident_start = function
  | 'A' .. 'Z' | 'a' .. 'z' | '_' -> true
  | _ -> false

let is_ident_char = function
  | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_' -> true
  | _ -> false

let parse_symbol_at s i =
  let len = String.length s in
  if i >= len || not (is_ident_start s.[i]) then None
  else
    let j = ref (i + 1) in
    while !j < len && is_ident_char s.[!j] do incr j done;
    let rec loop k =
      if k >= len then Some k
      else if s.[k] = '-' then begin
        let after_sep =
          if k + 1 < len && s.[k + 1] = '>' then k + 2 else k + 1
        in
        if after_sep >= len || not (is_ident_char s.[after_sep]) then Some k
        else
          let t = ref (after_sep + 1) in
          while !t < len && is_ident_char s.[!t] do incr t done;
          loop !t
      end else if s.[k] = '?' then begin
        if k + 1 >= len then Some (k + 1)
        else if not (is_ident_char s.[k + 1]) then Some k
        else
          let t = ref (k + 2) in
          while !t < len && is_ident_char s.[!t] do incr t done;
          loop !t
      end else
        Some k
    in
    loop !j

let parse_module_at s i =
  let len = String.length s in
  if i >= len || not (is_ident_start s.[i]) then None
  else
    let j = ref (i + 1) in
    while !j < len && is_ident_char s.[!j] do incr j done;
    let rec loop k =
      if k < len && s.[k] = '-' && k + 1 < len && is_ident_char s.[k + 1] then
        let t = ref (k + 2) in
        while !t < len && is_ident_char s.[!t] do incr t done;
        loop !t
      else
        Some k
    in
    loop !j

let is_symbol_name name =
  match parse_symbol_at name 0 with
  | Some idx -> idx = String.length name
  | None -> false

let is_module_name name =
  match parse_module_at name 0 with
  | Some idx -> idx = String.length name
  | None -> false

let is_global_name name =
  if not (is_symbol_name name) then false
  else
    let has_upper = ref false in
    let has_lower = ref false in
    String.iter (function
      | 'A' .. 'Z' -> has_upper := true
      | 'a' .. 'z' -> has_lower := true
      | _ -> ()
    ) name;
    !has_upper && not !has_lower

let is_local_name name =
  if not (is_symbol_name name) then false
  else
    let has_upper = ref false in
    String.iter (function
      | 'A' .. 'Z' -> has_upper := true
      | _ -> ()
    ) name;
    not !has_upper

let global_decl_equal a b =
  a.required = b.required
  && a.has_default = b.has_default
  && a.default_expr = b.default_expr

let predeclare_global_if_missing name =
  if not (Hashtbl.mem global_decls name) then
    Hashtbl.replace global_decls name { required = false; has_default = false; default_expr = None }

let require_declared_global name where verb =
  if !strict_globals_mode && not (Hashtbl.mem global_decls name) then
    failwith (Printf.sprintf "%s: undeclared global %s: '$%s'" where verb name)

let parse_global_decl_modifier raw =
  match raw with
  | None -> { required = false; has_default = false; default_expr = None }
  | Some raw ->
    let raw = String.trim raw in
    if raw = "" then
      { required = false; has_default = false; default_expr = None }
    else if raw = "required" then
      { required = true; has_default = false; default_expr = None }
    else if Str.string_match re_global_default raw 0 then
      let default_expr = Str.matched_group 1 raw in
      { required = false; has_default = true; default_expr = Some default_expr }
    else
      failwith "global: expected 'required' or 'default(<expr>)'"

let declare_global_spec name spec where =
  if not (is_global_name name) then
    failwith (Printf.sprintf "%s: global name must be uppercase: '$%s'" where name);
  match hashtbl_find_opt global_decls name with
  | Some existing ->
    if not (global_decl_equal existing spec) then
      failwith (Printf.sprintf "%s: conflicting declaration for '$%s'" where name)
  | None ->
    Hashtbl.replace global_decls name spec

let validate_required_globals_runtime () =
  Hashtbl.iter (fun name decl ->
    if decl.required && not decl.has_default && not (Hashtbl.mem globals name) then
      failwith (Printf.sprintf "required global is not assigned at runtime: '$%s'" name)
  ) global_decls

let split_qualified_symbol token =
  match String.split_on_char '/' token with
  | [name] when is_symbol_name name -> Some (None, name)
  | [module_name; name] when is_module_name module_name && is_symbol_name name ->
    Some (Some module_name, name)
  | _ -> None

let split_qualified_func token =
  match String.split_on_char '/' token with
  | [name] when is_symbol_name name -> Some (None, name)
  | [first; second] when is_symbol_name first && is_symbol_name second ->
    Some (Some first, second)
  | _ -> None

let parse_func_call expr =
  let len = String.length expr in
  match parse_symbol_at expr 0 with
  | None -> None
  | Some name_end ->
    let fname, after_fname =
      if name_end < len && expr.[name_end] = '/' then
        match parse_symbol_at expr (name_end + 1) with
        | Some end2 ->
          (String.sub expr 0 end2, end2)
        | None ->
          ("", -1)
      else
        (String.sub expr 0 name_end, name_end)
    in
    if after_fname < 0 || fname = "" then None
    else
      let j = ref after_fname in
      while !j < len && (expr.[!j] = ' ' || expr.[!j] = '\t') do incr j done;
      if !j >= len || expr.[!j] <> '(' then None
      else
        let rec find_last_non_space k =
          if k < 0 then -1
          else if expr.[k] = ' ' || expr.[k] = '\t' then find_last_non_space (k - 1)
          else k
        in
        let last = find_last_non_space (len - 1) in
        if last <= !j || expr.[last] <> ')' then None
        else
          let raw_args = String.sub expr (!j + 1) (last - !j - 1) in
          Some (fname, raw_args)

let get_global_var name =
  match hashtbl_find_opt globals name with
  | Some v -> v
  | None -> Nil

let get_module_var module_name name =
  match module_var_lookup module_name name with
  | Some v -> v
  | None -> Nil

let get_module_array module_name name =
  let arrays = module_arrays_ref module_name in
  match hashtbl_find_opt arrays name with
  | Some v -> v
  | None -> Arr (dynarr_empty ())

let get_module_dict module_name name =
  let dicts = module_dicts_ref module_name in
  match hashtbl_find_opt dicts name with
  | Some v -> v
  | None -> Dict (Hashtbl.create 4)

let get_global_array name =
  match hashtbl_find_opt global_arrays name with
  | Some v -> v
  | None -> Arr (dynarr_empty ())

let get_global_dict name =
  match hashtbl_find_opt global_dicts name with
  | Some v -> v
  | None -> Dict (Hashtbl.create 4)

let module_name_from_file file =
  let base = Filename.basename file in
  let name =
    match string_rindex_opt base '.' with
    | Some idx when idx > 0 -> String.sub base 0 idx
    | _ -> base
  in
  if is_module_name name then name
  else failwith ("load: invalid module name '" ^ name ^ "'")

let has_extension file =
  let base = Filename.basename file in
  String.contains base '.'

let default_load_extensions = [".es"]

let file_exists path =
  Sys.file_exists path &&
  (try not (Sys.is_directory path) with _ -> false)

let resolve_load_path file =
  let candidates = ref [] in
  let add p = candidates := p :: !candidates in
  if is_relative_path file then begin
    let base_dir = match hashtbl_find_opt module_dirs !current_module with
      | Some d -> d
      | None -> "." in
    add (Filename.concat base_dir file);
    if not (has_extension file) then begin
      List.iter (fun ext -> add (Filename.concat base_dir (file ^ ext))) default_load_extensions
    end;
    add file;
    if not (has_extension file) then begin
      List.iter (fun ext -> add (file ^ ext)) default_load_extensions
    end
  end else begin
    add file;
    if not (has_extension file) then begin
      List.iter (fun ext -> add (file ^ ext)) default_load_extensions
    end
  end;
  let rec pick = function
    | [] -> file
    | c :: rest -> if file_exists c then c else pick rest
  in
  pick (List.rev !candidates)

let canonicalize_path path =
  let abs =
    if is_relative_path path then
      Filename.concat (Sys.getcwd ()) path
    else
      path
  in
  try Unix.realpath abs with _ -> abs

let format_load_cycle next_abs_path =
  String.concat " -> " ((List.rev !module_load_stack) @ [next_abs_path])

let resolve_sub_target fname =
  match split_qualified_func fname with
  | Some (Some module_name, sub_name) when is_module_name module_name ->
    let subs = module_subs_ref module_name in
    if Hashtbl.mem subs sub_name then Some (module_name, sub_name) else None
  | Some (None, sub_name) ->
    let curr_subs = module_subs_ref !current_module in
    if Hashtbl.mem curr_subs sub_name then Some (!current_module, sub_name)
    else
      let main_subs = module_subs_ref main_module in
      if Hashtbl.mem main_subs sub_name then Some (main_module, sub_name)
      else None
  | _ -> None

let is_string_literal s =
  let len = String.length s in
  if len < 2 || s.[0] <> '"' || s.[len - 1] <> '"' then false
  else
    let in_escape = ref false in
    let ok = ref true in
    for i = 1 to len - 2 do
      let ch = s.[i] in
      if !in_escape then
        in_escape := false
      else if ch = '\\' then
        in_escape := true
      else if ch = '"' then
        ok := false
    done;
    !ok

(* ============================================================
   parse_arglist — split on comma at depth 0
   ============================================================ *)

let parse_arglist str =
  let len = String.length str in
  let buf = Buffer.create 32 in
  let args = ref [] in
  let depth = ref 0 in
  let in_quote = ref false in
  let escaped = ref false in
  for i = 0 to len - 1 do
    let ch = str.[i] in
    if !in_quote then begin
      if !escaped then begin
        escaped := false;
        Buffer.add_char buf ch
      end else if ch = '\\' then begin
        escaped := true;
        Buffer.add_char buf ch
      end else if ch = '"' then begin
        in_quote := false;
        Buffer.add_char buf ch
      end else
        Buffer.add_char buf ch
    end else if ch = '"' then begin
      in_quote := true;
      Buffer.add_char buf ch
    end else if ch = '(' || ch = '[' || ch = '{' then begin
      incr depth;
      Buffer.add_char buf ch
    end else if ch = ')' || ch = ']' || ch = '}' then begin
      decr depth;
      Buffer.add_char buf ch
    end else if ch = ',' && !depth = 0 then begin
      args := Buffer.contents buf :: !args;
      Buffer.clear buf
    end else
      Buffer.add_char buf ch
  done;
  if !in_quote then
    failwith ("Unterminated string in argument list: '" ^ str ^ "'");
  if !depth <> 0 then
    failwith ("Unbalanced brackets in argument list: '" ^ str ^ "'");
  let last = Buffer.contents buf in
  if String.trim last <> "" then args := last :: !args;
  List.rev !args

let parse_plain_string_literal raw =
  let len = String.length raw in
  let buf = Buffer.create len in
  let i = ref 0 in
  while !i < len do
    let ch = raw.[!i] in
    if ch = '\\' then begin
      incr i;
      if !i >= len then Buffer.add_char buf '\\'
      else begin
        let esc = raw.[!i] in
        match esc with
        | 'n' -> Buffer.add_char buf '\n'
        | 't' -> Buffer.add_char buf '\t'
        | 'r' -> Buffer.add_char buf '\r'
        | '"' | '\\' | '$' -> Buffer.add_char buf esc
        | _ -> Buffer.add_char buf '\\'; Buffer.add_char buf esc
      end
    end else
      Buffer.add_char buf ch;
    incr i
  done;
  Buffer.contents buf

type static_load_target =
  | Static_load_dynamic
  | Static_load_literal of string

type static_state = {
  seen : (string, bool) Hashtbl.t;
  decls : (string, global_decl) Hashtbl.t;
  assigned : (string, bool) Hashtbl.t;
  errors : string list ref;
}

let static_add_error state msg =
  state.errors := msg :: !(state.errors)

let resolve_load_path_from_file from_file target =
  let candidates = ref [] in
  let add p = candidates := p :: !candidates in
  if is_relative_path target then begin
    let base_dir = Filename.dirname from_file in
    add (Filename.concat base_dir target);
    if not (has_extension target) then begin
      List.iter (fun ext -> add (Filename.concat base_dir (target ^ ext))) default_load_extensions
    end;
    add target;
    if not (has_extension target) then begin
      List.iter (fun ext -> add (target ^ ext)) default_load_extensions
    end
  end else begin
    add target;
    if not (has_extension target) then begin
      List.iter (fun ext -> add (target ^ ext)) default_load_extensions
    end
  end;
  let rec pick = function
    | [] -> None
    | c :: rest -> if file_exists c then Some c else pick rest
  in
  pick (List.rev !candidates)

let parse_load_literal_target line =
  match parse_func_call line with
  | Some ("load", raw_args) ->
    let target =
      try
        let args = parse_arglist raw_args in
        match args with
        | [arg] ->
          let arg = String.trim arg in
          if is_string_literal arg then
            Static_load_literal
              (parse_plain_string_literal (String.sub arg 1 (String.length arg - 2)))
          else
            Static_load_dynamic
        | _ ->
          Static_load_dynamic
      with Failure _ ->
        Static_load_dynamic
    in
    Some target
  | _ -> None

let rec static_scan_file path state =
  if Hashtbl.mem state.seen path then ()
  else begin
    Hashtbl.replace state.seen path true;
    let lines =
      try
        let ic = open_in path in
        let lines = ref [] in
        (try while true do lines := input_line ic :: !lines done
         with End_of_file -> ());
        close_in ic;
        List.rev !lines
      with Sys_error msg ->
        static_add_error state (path ^ ": cannot open: " ^ msg);
        []
    in
    let arr = Array.of_list lines in
    for i = 0 to Array.length arr - 1 do
      let line = String.trim arr.(i) in
      if not (is_blank_or_comment line) then begin
        let where = Printf.sprintf "%s:%d" path (i + 1) in
        if re_matches re_global_decl line then begin
          let name = Str.matched_group 1 line in
          let raw_mod =
            try Some (Str.matched_group 3 line)
            with Not_found -> None
          in
          (try
             let spec = parse_global_decl_modifier raw_mod in
             if not (is_global_name name) then
               static_add_error state
                 (Printf.sprintf "%s: global name must be uppercase: '$%s'" where name)
             else
               (match hashtbl_find_opt state.decls name with
               | Some existing ->
                 if not (global_decl_equal existing spec) then
                   static_add_error state
                     (Printf.sprintf "%s: conflicting declaration for '$%s'" where name)
               | None ->
                 Hashtbl.replace state.decls name spec)
           with Failure msg ->
             static_add_error state (where ^ ": " ^ msg))
        end else if re_matches re_global_set line then begin
          let name = Str.matched_group 1 line in
          if not (is_global_name name) then
            static_add_error state
              (Printf.sprintf "%s: global names must be uppercase: '$%s'" where name)
          else
            Hashtbl.replace state.assigned name true
        end else if re_matches re_set_var line then begin
          let name = Str.matched_group 2 line in
          if is_global_name name then
            Hashtbl.replace state.assigned name true
          else if not (is_local_name name) then
            static_add_error state
              (Printf.sprintf "%s: local variable names must be lowercase: '$%s'" where name)
        end;
        match parse_load_literal_target line with
        | Some Static_load_dynamic ->
          static_add_error state
            (Printf.sprintf "%s: static check requires load(\"literal\")" where)
        | Some (Static_load_literal target) ->
          (match resolve_load_path_from_file path target with
          | Some resolved ->
            static_scan_file resolved state
          | None ->
            static_add_error state
              (Printf.sprintf "%s: cannot statically resolve load('%s')" where target))
        | None -> ()
      end
    done
  end

let run_static_check entry =
  let state = {
    seen = Hashtbl.create 32;
    decls = Hashtbl.create 32;
    assigned = Hashtbl.create 32;
    errors = ref [];
  } in
  static_scan_file entry state;
  Hashtbl.iter (fun name _ ->
    if not (Hashtbl.mem state.decls name) then
      static_add_error state (Printf.sprintf "undeclared global assignment: '$%s'" name)
  ) state.assigned;
  Hashtbl.iter (fun name decl ->
    if decl.required && not decl.has_default && not (Hashtbl.mem state.assigned name) then
      static_add_error state
        (Printf.sprintf "required global is never assigned: '$%s'" name)
  ) state.decls;
  let errs = List.rev !(state.errors) in
  if errs = [] then
    true
  else begin
    List.iter prerr_endline errs;
    false
  end

let parse_string_literal raw =
  let len = String.length raw in
  let buf = Buffer.create len in
  let i = ref 0 in
  while !i < len do
    let ch = raw.[!i] in
    if ch = '\\' then begin
      incr i;
      if !i >= len then Buffer.add_char buf '\\'
      else begin
        let esc = raw.[!i] in
        match esc with
        | 'n' -> Buffer.add_char buf '\n'
        | 't' -> Buffer.add_char buf '\t'
        | 'r' -> Buffer.add_char buf '\r'
        | '"' | '\\' | '$' -> Buffer.add_char buf esc
        | _ -> Buffer.add_char buf '\\'; Buffer.add_char buf esc
      end
    end else if ch = '$' then begin
      if !i + 1 < len then begin
        match parse_symbol_at raw (!i + 1) with
        | Some first_end when first_end > !i + 1 ->
          let first = String.sub raw (!i + 1) (first_end - !i - 1) in
          let qualified_done =
            if first_end < len && raw.[first_end] = '/' && is_module_name first then
              match parse_symbol_at raw (first_end + 1) with
              | Some second_end when second_end > first_end + 1 ->
                let name = String.sub raw (first_end + 1) (second_end - first_end - 1) in
                let repl =
                  if is_global_name name then
                    (require_declared_global name "string interpolation" "read";
                    get_global_var name)
                  else if is_local_name name then
                    get_module_var first name
                  else
                    failwith ("Invalid local variable name '$" ^ name ^ "' (locals must be lowercase)")
                in
                Buffer.add_string buf (to_str repl);
                i := second_end - 1;
                true
              | _ -> false
            else false
          in
          if not qualified_done then begin
            let repl =
              if is_global_name first then
                (require_declared_global first "string interpolation" "read";
                get_global_var first)
              else if is_local_name first then
                (match module_var_lookup !current_module first with
                | Some v -> v
                | None -> get_global_var first)
              else
                failwith ("Invalid local variable name '$" ^ first ^ "' (locals must be lowercase)")
            in
            Buffer.add_string buf (to_str repl);
            i := first_end - 1
          end
        | _ ->
          Buffer.add_char buf '$'
      end else
        Buffer.add_char buf '$'
    end else
      Buffer.add_char buf ch;
    incr i
  done;
  Str (Buffer.contents buf)

let split_dict_pair pair =
  let len = String.length pair in
  let depth = ref 0 in
  let in_quote = ref false in
  let escaped = ref false in
  let found = ref None in
  let i = ref 0 in
  while !i < len && !found = None do
    let ch = pair.[!i] in
    if !in_quote then begin
      if !escaped then
        escaped := false
      else if ch = '\\' then
        escaped := true
      else if ch = '"' then
        in_quote := false
    end else if ch = '"' then
      in_quote := true
    else begin
      if ch = '(' || ch = '[' || ch = '{' then incr depth
      else if ch = ')' || ch = ']' || ch = '}' then decr depth
      else if ch = ':' && !depth = 0 then
        found := Some !i
    end;
    incr i
  done;
  match !found with
  | None -> None
  | Some idx ->
    let left = String.sub pair 0 idx in
    let right = String.sub pair (idx + 1) (len - idx - 1) in
    Some (left, right)

type light_token =
  | LTNum of string
  | LTStr of string
  | LTBool of bool
  | LTNil
  | LTIdent of string
  | LTKeywordLit of string
  | LTRegex of string * string
  | LTSubst of string * string * string
  | LTOp of string
  | LTPunct of char
  | LTEof

type light_ast =
  | LANum of string
  | LAStr of string
  | LABool of bool
  | LANil
  | LAIdent of string
  | LARegex of string * string
  | LASubst of string * string * string
  | LAArray of light_ast list
  | LADict of (light_ast * light_ast) list
  | LACall of light_ast * light_ast list
  | LAIndex of light_ast * light_ast
  | LAUnary of string * light_ast
  | LABin of string * light_ast * light_ast

let re_light_dash_symbol =
  Str.regexp {|[A-Za-z_][A-Za-z0-9_]*-[A-Za-z0-9_]|}
let re_light_module_call =
  Str.regexp {|[A-Za-z_][A-Za-z0-9_]*/[A-Za-z_][A-Za-z0-9_]*[ 	]*(|}
let re_light_true_false_call =
  Str.regexp {|\<\(true\|false\)[ 	]*(|}

let string_starts_with_at s i prefix =
  let plen = String.length prefix in
  let slen = String.length s in
  i + plen <= slen && String.sub s i plen = prefix

let contains_sigils s =
  let found = ref false in
  String.iter (fun ch ->
    if ch = '$' || ch = '@' || ch = '%' then found := true
  ) s;
  !found

let is_light_ident name =
  let len = String.length name in
  if len = 0 || not (is_ident_start name.[0]) then false
  else
    let ok = ref true in
    for i = 1 to len - 1 do
      if not (is_ident_char name.[i]) then ok := false
    done;
    !ok

let light_escape_string raw =
  let buf = Buffer.create (String.length raw + 8) in
  Buffer.add_char buf '"';
  String.iter (fun ch ->
    match ch with
    | '\\' -> Buffer.add_string buf "\\\\"
    | '"' -> Buffer.add_string buf "\\\""
    | '\n' -> Buffer.add_string buf "\\n"
    | '\r' -> Buffer.add_string buf "\\r"
    | '\t' -> Buffer.add_string buf "\\t"
    | _ -> Buffer.add_char buf ch
  ) raw;
  Buffer.add_char buf '"';
  Buffer.contents buf

let light_regex_literal_to_sup pat flags =
  let mods = Buffer.create 4 in
  if String.contains flags 'i' then Buffer.add_char mods 'i';
  if String.contains flags 'm' then Buffer.add_char mods 'm';
  if String.contains flags 's' then Buffer.add_char mods 's';
  let full =
    let m = Buffer.contents mods in
    if m = "" then pat else "(?" ^ m ^ ":" ^ pat ^ ")"
  in
  let escaped = Buffer.create (String.length full + 8) in
  String.iter (fun ch ->
    if ch = '\\' then Buffer.add_string escaped "\\\\"
    else if ch = '"' then Buffer.add_string escaped "\\\""
    else Buffer.add_char escaped ch
  ) full;
  "#\"" ^ Buffer.contents escaped ^ "\""

let light_read_quoted s start =
  let len = String.length s in
  let buf = Buffer.create 16 in
  let i = ref start in
  let escaped = ref false in
  let closed = ref false in
  while !i < len && not !closed do
    let ch = s.[!i] in
    if !escaped then begin
      escaped := false;
      Buffer.add_char buf ch;
      incr i
    end else if ch = '\\' then begin
      escaped := true;
      Buffer.add_char buf ch;
      incr i
    end else if ch = '"' then
      closed := true
    else begin
      Buffer.add_char buf ch;
      incr i
    end
  done;
  if not !closed then failwith "unterminated string literal";
  (Buffer.contents buf, !i + 1)

let light_read_slash s start =
  let len = String.length s in
  let buf = Buffer.create 16 in
  let i = ref start in
  let escaped = ref false in
  let closed = ref false in
  while !i < len && not !closed do
    let ch = s.[!i] in
    if !escaped then begin
      escaped := false;
      Buffer.add_char buf ch;
      incr i
    end else if ch = '\\' then begin
      escaped := true;
      Buffer.add_char buf ch;
      incr i
    end else if ch = '/' then
      closed := true
    else begin
      Buffer.add_char buf ch;
      incr i
    end
  done;
  if not !closed then failwith "unterminated regex literal";
  (Buffer.contents buf, !i + 1)

let light_read_flags s start =
  let len = String.length s in
  let rec scan j =
    if j >= len then j
    else
      match s.[j] with
      | 'A' .. 'Z' | 'a' .. 'z' -> scan (j + 1)
      | _ -> j
  in
  let j = scan start in
  (String.sub s start (j - start), j)

let light_tokenize_expr expr =
  let len = String.length expr in
  let rec loop i prev_op acc =
    let rec skip_ws j =
      if j < len && (expr.[j] = ' ' || expr.[j] = '\t') then skip_ws (j + 1)
      else j
    in
    let i = skip_ws i in
    if i >= len then List.rev (LTEof :: acc)
    else
      let push token next prev =
        loop next prev (token :: acc)
      in
      if prev_op = Some "=~" && i + 1 < len && expr.[i] = 's' && expr.[i + 1] = '/' then begin
        let pat, after_pat = light_read_slash expr (i + 2) in
        let rep, after_rep = light_read_slash expr after_pat in
        let flags, next_i = light_read_flags expr after_rep in
        push (LTSubst (pat, rep, flags)) next_i None
      end else if (prev_op = Some "=~" || prev_op = Some "!~") && expr.[i] = '/' then begin
        let pat, after_pat = light_read_slash expr (i + 1) in
        let flags, next_i = light_read_flags expr after_pat in
        push (LTRegex (pat, flags)) next_i None
      end else
        match expr.[i] with
        | '"' ->
          let raw, next_i = light_read_quoted expr (i + 1) in
          push (LTStr raw) next_i None
        | '0' .. '9' ->
          let j = ref i in
          while !j < len && match expr.[!j] with '0' .. '9' -> true | _ -> false do incr j done;
          if !j < len && expr.[!j] = '.' then begin
            incr j;
            while !j < len && match expr.[!j] with '0' .. '9' -> true | _ -> false do incr j done
          end;
          push (LTNum (String.sub expr i (!j - i))) !j None
        | c when is_ident_start c ->
          let j = ref (i + 1) in
          while !j < len && is_ident_char expr.[!j] do incr j done;
          let word = String.sub expr i (!j - i) in
          if !j < len && expr.[!j] = ':' then
            push (LTKeywordLit word) (!j + 1) None
          else
            let token, prev =
              if word = "and" || word = "or" || word = "not" then
                (LTOp word, Some word)
              else if word = "true" then
                (LTBool true, None)
              else if word = "false" then
                (LTBool false, None)
              else if word = "nil" then
                (LTNil, None)
              else
                (LTIdent word, None)
            in
            push token !j prev
        | _ ->
          let multi_ops = [ "=="; "!="; "<="; ">="; "=~"; "!~"; "++" ] in
          let rec find_op = function
            | [] -> None
            | op :: rest ->
              if string_starts_with_at expr i op then Some op else find_op rest
          in
          (match find_op multi_ops with
          | Some op ->
            push (LTOp op) (i + String.length op) (Some op)
          | None ->
            let ch = expr.[i] in
            if ch = '+' || ch = '-' || ch = '*' || ch = '/' || ch = '%' || ch = '<' || ch = '>' then
              push (LTOp (String.make 1 ch)) (i + 1) (Some (String.make 1 ch))
            else if ch = '(' || ch = ')' || ch = '[' || ch = ']' || ch = '{' || ch = '}' || ch = ',' || ch = ':' then
              push (LTPunct ch) (i + 1) None
            else
              failwith ("unsupported expression token near: " ^ String.sub expr i (min 20 (len - i))))
  in
  loop 0 None []

let light_peek tokens pos =
  if !pos < Array.length tokens then tokens.(!pos) else LTEof

let light_next tokens pos =
  let tok = light_peek tokens pos in
  pos := !pos + 1;
  tok

let expect_light_punct tokens pos ch =
  match light_next tokens pos with
  | LTPunct c when c = ch -> ()
  | _ -> failwith (Printf.sprintf "expected '%c'" ch)

let rec light_parse_expr tokens pos = light_parse_or tokens pos

and light_parse_or tokens pos =
  let rec loop left =
    match light_peek tokens pos with
    | LTOp "or" ->
      ignore (light_next tokens pos);
      let right = light_parse_and tokens pos in
      loop (LABin ("or", left, right))
    | _ -> left
  in
  loop (light_parse_and tokens pos)

and light_parse_and tokens pos =
  let rec loop left =
    match light_peek tokens pos with
    | LTOp "and" ->
      ignore (light_next tokens pos);
      let right = light_parse_cmp tokens pos in
      loop (LABin ("and", left, right))
    | _ -> left
  in
  loop (light_parse_cmp tokens pos)

and light_parse_cmp tokens pos =
  let rec loop left =
    match light_peek tokens pos with
    | LTOp ("==" | "!=" | "<" | ">" | "<=" | ">=" | "=~" | "!~" as op) ->
      ignore (light_next tokens pos);
      let right = light_parse_add tokens pos in
      loop (LABin (op, left, right))
    | _ -> left
  in
  loop (light_parse_add tokens pos)

and light_parse_add tokens pos =
  let rec loop left =
    match light_peek tokens pos with
    | LTOp ("+" | "-" | "++" as op) ->
      ignore (light_next tokens pos);
      let right = light_parse_mul tokens pos in
      loop (LABin (op, left, right))
    | _ -> left
  in
  loop (light_parse_mul tokens pos)

and light_parse_mul tokens pos =
  let rec loop left =
    match light_peek tokens pos with
    | LTOp ("*" | "/" | "%" as op) ->
      ignore (light_next tokens pos);
      let right = light_parse_unary tokens pos in
      loop (LABin (op, left, right))
    | _ -> left
  in
  loop (light_parse_unary tokens pos)

and light_parse_unary tokens pos =
  match light_peek tokens pos with
  | LTOp ("not" | "+" | "-" as op) ->
    ignore (light_next tokens pos);
    LAUnary (op, light_parse_unary tokens pos)
  | _ ->
    light_parse_postfix tokens pos

and light_parse_postfix tokens pos =
  let rec loop node =
    match light_peek tokens pos with
    | LTPunct '(' ->
      ignore (light_next tokens pos);
      let args =
        match light_peek tokens pos with
        | LTPunct ')' -> []
        | _ ->
          let rec parse_args acc =
            let arg = light_parse_expr tokens pos in
            match light_peek tokens pos with
            | LTPunct ',' ->
              ignore (light_next tokens pos);
              parse_args (arg :: acc)
            | _ -> List.rev (arg :: acc)
          in
          parse_args []
      in
      expect_light_punct tokens pos ')';
      loop (LACall (node, args))
    | LTPunct '[' ->
      ignore (light_next tokens pos);
      let idx = light_parse_expr tokens pos in
      expect_light_punct tokens pos ']';
      loop (LAIndex (node, idx))
    | _ -> node
  in
  loop (light_parse_primary tokens pos)

and light_parse_primary tokens pos =
  match light_next tokens pos with
  | LTNum s -> LANum s
  | LTStr s -> LAStr s
  | LTBool b -> LABool b
  | LTNil -> LANil
  | LTRegex (pat, flags) -> LARegex (pat, flags)
  | LTSubst (pat, rep, flags) -> LASubst (pat, rep, flags)
  | LTKeywordLit s -> LAStr s
  | LTIdent s -> LAIdent s
  | LTPunct '(' ->
    let inner = light_parse_expr tokens pos in
    expect_light_punct tokens pos ')';
    inner
  | LTPunct '[' ->
    let items =
      match light_peek tokens pos with
      | LTPunct ']' -> []
      | _ ->
        let rec parse_items acc =
          let v = light_parse_expr tokens pos in
          match light_peek tokens pos with
          | LTPunct ',' ->
            ignore (light_next tokens pos);
            parse_items (v :: acc)
          | _ -> List.rev (v :: acc)
        in
        parse_items []
    in
    expect_light_punct tokens pos ']';
    LAArray items
  | LTPunct '{' ->
    let pairs =
      match light_peek tokens pos with
      | LTPunct '}' -> []
      | _ ->
        let rec parse_pairs acc =
          let key =
            match light_peek tokens pos with
            | LTKeywordLit k ->
              ignore (light_next tokens pos);
              LAStr k
            | _ ->
              let k = light_parse_expr tokens pos in
              expect_light_punct tokens pos ':';
              k
          in
          let value = light_parse_expr tokens pos in
          match light_peek tokens pos with
          | LTPunct ',' ->
            ignore (light_next tokens pos);
            parse_pairs ((key, value) :: acc)
          | _ ->
            List.rev ((key, value) :: acc)
        in
        parse_pairs []
    in
    expect_light_punct tokens pos '}';
    LADict pairs
  | LTEof ->
    failwith "unexpected end of expression"
  | _ ->
    failwith "unexpected token in expression"

let rec light_ast_to_sup ?(as_callee = false) node =
  match node with
  | LANum s -> s
  | LAStr s -> light_escape_string s
  | LABool b -> if b then "1" else "0"
  | LANil -> "nil"
  | LAIdent s -> if as_callee then s else "$" ^ s
  | LARegex (pat, flags) -> light_regex_literal_to_sup pat flags
  | LASubst _ -> failwith "substitution token can only be used with '=~'"
  | LAArray items ->
    "[" ^ String.concat ", " (List.map (light_ast_to_sup ~as_callee:false) items) ^ "]"
  | LADict pairs ->
    let rendered =
      List.map (fun (k, v) ->
        light_ast_to_sup ~as_callee:false k ^ ": " ^ light_ast_to_sup ~as_callee:false v
      ) pairs
    in
    "{" ^ String.concat ", " rendered ^ "}"
  | LACall (callee, args) ->
    let fn = light_ast_to_sup ~as_callee:true callee in
    if String.length fn > 0 && fn.[0] = '$' then
      failwith "call target must be an identifier";
    fn ^ "(" ^ String.concat ", " (List.map (light_ast_to_sup ~as_callee:false) args) ^ ")"
  | LAIndex (base, idx) ->
    "get(" ^ light_ast_to_sup ~as_callee:false base ^ ", "
    ^ light_ast_to_sup ~as_callee:false idx ^ ")"
  | LAUnary (op, rhs) ->
    let rhs = light_ast_to_sup ~as_callee:false rhs in
    if op = "+" then rhs
    else if op = "-" then "sub(0, " ^ rhs ^ ")"
    else if op = "not" then "not(" ^ rhs ^ ")"
    else failwith ("unsupported unary operator '" ^ op ^ "'")
  | LABin (op, left, right) ->
    let lhs = light_ast_to_sup ~as_callee:false left in
    if op = "=~" then
      (match right with
      | LASubst (pat, rep, flags) ->
        "rx-sub(" ^ lhs ^ ", " ^ light_escape_string pat ^ ", "
        ^ light_escape_string rep ^ ", " ^ light_escape_string flags ^ ")"
      | _ ->
        let rhs = light_ast_to_sup ~as_callee:false right in
        "matchrx(" ^ lhs ^ ", " ^ rhs ^ ")")
    else if op = "!~" then
      let rhs = light_ast_to_sup ~as_callee:false right in
      "not(matchrx(" ^ lhs ^ ", " ^ rhs ^ "))"
    else
      let rhs = light_ast_to_sup ~as_callee:false right in
      let fn =
        match op with
        | "+" -> "add"
        | "-" -> "sub"
        | "*" -> "mul"
        | "/" -> "div"
        | "%" -> "mod"
        | "++" -> "concat"
        | "==" -> "eq"
        | "!=" -> "neq"
        | "<" -> "lt"
        | ">" -> "gt"
        | "<=" -> "lte"
        | ">=" -> "gte"
        | "and" -> "and"
        | "or" -> "or"
        | _ -> failwith ("unsupported operator '" ^ op ^ "'")
      in
      fn ^ "(" ^ lhs ^ ", " ^ rhs ^ ")"

let maybe_normalize_light_expr expr =
  let trim = String.trim expr in
  if trim = "" then expr
  else if trim.[0] = '$' || trim.[0] = '@' || trim.[0] = '%' || trim.[0] = '#' then expr
  else if contains_sigils trim then expr
  else
    try
      let toks = Array.of_list (light_tokenize_expr trim) in
      let pos = ref 0 in
      let ast = light_parse_expr toks pos in
      (match light_peek toks pos with
      | LTEof -> light_ast_to_sup ast
      | _ -> expr)
    with Failure _ ->
      expr

type light_block_meta =
  | LightIf of int
  | LightOther

let parse_light_param_list raw label =
  let parts =
    String.split_on_char ',' raw
    |> List.map String.trim
    |> List.filter (fun s -> s <> "")
  in
  List.iter (fun p ->
    if not (is_light_ident p) then
      failwith ("Invalid parameter name '" ^ p ^ "' in " ^ label)
  ) parts;
  parts

let opens_block_for_light line =
  re_matches re_if line
  || re_matches re_when line
  || re_matches re_unless line
  || re_matches re_while line
  || re_matches re_switch line
  || re_matches re_sub_def line
  || re_matches re_foreach line
  || re_matches re_fori line
  || re_matches re_light_if_then line
  || re_matches re_light_while_do line
  || re_matches re_light_foreach_do line
  || re_matches re_light_defun_prefix line
  || re_matches re_light_fun_assign_let_def line
  || re_matches re_light_fun_assign line

let collect_light_do_block lines start label =
  let len = Array.length lines in
  let rec loop i depth acc =
    if i >= len then
      failwith (label ^ " without matching end")
    else
      let raw = lines.(i) in
      let line = String.trim raw in
      if is_blank_or_comment line then
        loop (i + 1) depth (raw :: acc)
      else if line = "end" then
        if depth = 1 then
          (List.rev acc, i + 1)
        else
          loop (i + 1) (depth - 1) (raw :: acc)
      else if opens_block_for_light line then
        loop (i + 1) (depth + 1) (raw :: acc)
      else
        loop (i + 1) depth (raw :: acc)
  in
  loop start 1 []

let light_safe_call_candidate line =
  not (contains_sigils line)
  && (try ignore (Str.search_forward re_light_dash_symbol line 0); false with Not_found -> true)
  && (try ignore (Str.search_forward re_light_module_call line 0); false with Not_found -> true)
  && (try ignore (Str.search_forward re_light_true_false_call line 0); false with Not_found -> true)
  && (try ignore (String.index line '\\'); false with Not_found -> true)

let extract_balanced_parens str =
  if String.length str = 0 || str.[0] <> '(' then
    failwith "extract_balanced_parens: expected '(' at start";
  let len = String.length str in
  let depth = ref 0 in
  let in_quote = ref false in
  let escaped = ref false in
  let result = ref None in
  let i = ref 0 in
  while !i < len && !result = None do
    let ch = str.[!i] in
    if !in_quote && !escaped then begin
      escaped := false
    end else if !in_quote && ch = '\\' then begin
      escaped := true
    end else if ch = '"' then begin
      in_quote := not !in_quote
    end else if not !in_quote then begin
      if ch = '(' then
        incr depth
      else if ch = ')' then begin
        decr depth;
        if !depth = 0 then begin
          let inner = String.sub str 1 (!i - 1) in
          let rest = String.sub str (!i + 1) (len - !i - 1) in
          result := Some (inner, rest)
        end
      end
    end;
    incr i
  done;
  match !result with
  | Some r -> r
  | None -> failwith ("Unbalanced parentheses in: '" ^ str ^ "'")

let light_classify_parens content =
  let len = String.length content in
  let depth = ref 0 in
  let in_quote = ref false in
  let escaped = ref false in
  let found_comma = ref false in
  let i = ref 0 in
  while !i < len && not !found_comma do
    let ch = content.[!i] in
    if !in_quote && !escaped then
      escaped := false
    else if !in_quote && ch = '\\' then
      escaped := true
    else if ch = '"' then
      in_quote := not !in_quote
    else if not !in_quote then begin
      if ch = '(' || ch = '[' || ch = '{' then
        incr depth
      else if ch = ')' || ch = ']' || ch = '}' then
        decr depth
      else if ch = ',' && !depth = 0 then
        found_comma := true
    end;
    incr i
  done;
  if !found_comma then "arglist" else "expr"

let has_infix_ops_at_depth0 content =
  let tokens = try light_tokenize_expr content with _ -> [LTEof] in
  let depth = ref 0 in
  let prev_is_value = ref false in
  let found = ref false in
  List.iter (fun tok ->
    if not !found then
      match tok with
      | LTPunct c when c = '(' || c = '[' || c = '{' ->
        incr depth; prev_is_value := false
      | LTPunct c when c = ')' || c = ']' || c = '}' ->
        decr depth; prev_is_value := true
      | LTPunct _ ->
        prev_is_value := false
      | LTOp _ when !depth = 0 && !prev_is_value ->
        found := true
      | LTIdent _ | LTNum _ | LTStr _ | LTBool _ | LTNil | LTKeywordLit _ ->
        prev_is_value := true
      | _ ->
        prev_is_value := false
  ) tokens;
  !found

let light_collect_args tail =
  let tail = String.trim tail in
  if tail = "" then []
  else begin
    let len = String.length tail in
    let buf = Buffer.create 32 in
    let raw_tokens = ref [] in
    let depth = ref 0 in
    let in_quote = ref false in
    let escaped = ref false in
    for i = 0 to len - 1 do
      let ch = tail.[i] in
      if !in_quote && !escaped then begin
        escaped := false;
        Buffer.add_char buf ch
      end else if !in_quote && ch = '\\' then begin
        escaped := true;
        Buffer.add_char buf ch
      end else if ch = '"' then begin
        in_quote := not !in_quote;
        Buffer.add_char buf ch
      end else if !in_quote then
        Buffer.add_char buf ch
      else if ch = '(' || ch = '[' || ch = '{' then begin
        incr depth;
        Buffer.add_char buf ch
      end else if ch = ')' || ch = ']' || ch = '}' then begin
        decr depth;
        Buffer.add_char buf ch
      end else if !depth = 0 && (ch = ',' || ch = ' ' || ch = '\t') then begin
        let s = Buffer.contents buf in
        if String.trim s <> "" then
          raw_tokens := s :: !raw_tokens;
        Buffer.clear buf
      end else
        Buffer.add_char buf ch
    done;
    let last = Buffer.contents buf in
    if String.trim last <> "" then
      raw_tokens := last :: !raw_tokens;
    let raw_tokens = List.rev !raw_tokens in
    (* Post-process: splice arglist parens, keep expr parens whole *)
    let args = ref [] in
    List.iter (fun tok ->
      let trimmed = String.trim tok in
      if String.length trimmed > 0 && trimmed.[0] = '('
         && not (is_light_ident (String.sub trimmed 0 1)) then begin
        match (try Some (extract_balanced_parens trimmed) with Failure _ -> None) with
        | Some (inner, rest) when String.trim rest = "" ->
          let cls = light_classify_parens inner in
          if cls = "arglist" then begin
            let parts = parse_arglist inner in
            args := List.rev_append parts !args
          end else
            args := trimmed :: !args
        | _ ->
          args := trimmed :: !args
      end else
        args := trimmed :: !args
    ) raw_tokens;
    List.rev !args
  end

let light_fun_block_seq = ref 0

let rec normalize_light_program lines =
  let arr = Array.of_list lines in
  let len = Array.length arr in
  let rec loop i stack tmp_id acc =
    if i >= len then
      List.rev acc
    else
      let raw = arr.(i) in
      let line = String.trim raw in
      if is_blank_or_comment line then
        loop (i + 1) stack tmp_id (raw :: acc)
      else if re_matches re_light_defun_prefix line then
        let name = Str.matched_group 1 line in
        let rest = Str.matched_group 2 line in
        let params_opt =
          if re_matches re_light_defun_parens rest then
            Some (parse_light_param_list (Str.matched_group 1 rest) "defun")
          else if re_matches re_light_defun_brackets rest then
            Some (parse_light_param_list (Str.matched_group 1 rest) "defun")
          else if re_matches re_light_defun_no_params rest then
            Some []
          else if re_matches re_light_defun_bare_params rest then
            let params_str = Str.matched_group 1 rest in
            let parts =
              String.split_on_char ' ' params_str
              |> List.concat_map (String.split_on_char ',')
              |> List.concat_map (String.split_on_char '\t')
              |> List.map String.trim
              |> List.filter (fun s -> s <> "")
            in
            if List.for_all is_light_ident parts then Some parts
            else None
          else
            None
        in
        (match params_opt with
        | Some params ->
          let plist = String.concat ", " (List.map (fun p -> "$" ^ p) params) in
          loop (i + 1) (LightOther :: stack) tmp_id (("defun " ^ name ^ "(" ^ plist ^ ")") :: acc)
        | None ->
          loop (i + 1) stack tmp_id (raw :: acc))
      else if re_matches re_light_if_then line then
        let cond = Str.matched_group 1 line in
        loop (i + 1) (LightIf 0 :: stack) tmp_id (("if " ^ maybe_normalize_light_expr cond) :: acc)
      else if re_matches re_light_elif_then line then
        (match stack with
        | LightIf n :: rest ->
          let cond = Str.matched_group 1 line in
          let acc = ("if " ^ maybe_normalize_light_expr cond) :: ("else" :: acc) in
          loop (i + 1) (LightIf (n + 1) :: rest) tmp_id acc
        | _ ->
          loop (i + 1) stack tmp_id (raw :: acc))
      else if re_matches re_light_while_do line then
        let cond = Str.matched_group 1 line in
        loop (i + 1) (LightOther :: stack) tmp_id (("while " ^ maybe_normalize_light_expr cond) :: acc)
      else if re_matches re_light_foreach_do line then
        let var = Str.matched_group 1 line in
        let expr = Str.matched_group 2 line in
        let next_tmp = tmp_id + 1 in
        let tmp = "__foreach_" ^ string_of_int next_tmp in
        let acc =
          ("foreach $" ^ var ^ " @" ^ tmp)
          :: ("set @" ^ tmp ^ " = " ^ maybe_normalize_light_expr expr)
          :: acc
        in
        loop (i + 1) (LightOther :: stack) next_tmp acc
      else if re_matches re_light_fun_assign_let_def line then
        let kw = Str.matched_group 1 line in
        let var = Str.matched_group 2 line in
        let raw_params = Str.matched_group 3 line in
        let params = parse_light_param_list raw_params "fun" in
        let body_raw, next_i = collect_light_do_block arr (i + 1) "fun" in
        let body_norm = normalize_light_program body_raw in
        incr light_fun_block_seq;
        let fun_name = "__fun_block_" ^ string_of_int !light_fun_block_seq in
        let plist = String.concat ", " (List.map (fun p -> "$" ^ p) params) in
        let extra =
          [ "defun " ^ fun_name ^ "(" ^ plist ^ ")" ]
          @ body_norm
          @ [ "end"; kw ^ " $" ^ var ^ " = make-fun-ref(" ^ light_escape_string fun_name ^ ")" ]
        in
        let acc = List.fold_left (fun a l -> l :: a) acc extra in
        loop next_i stack tmp_id acc
      else if re_matches re_light_fun_assign line then
        let var = Str.matched_group 1 line in
        let raw_params = Str.matched_group 2 line in
        let params = parse_light_param_list raw_params "fun" in
        let body_raw, next_i = collect_light_do_block arr (i + 1) "fun" in
        let body_norm = normalize_light_program body_raw in
        incr light_fun_block_seq;
        let fun_name = "__fun_block_" ^ string_of_int !light_fun_block_seq in
        let plist = String.concat ", " (List.map (fun p -> "$" ^ p) params) in
        let extra =
          [ "defun " ^ fun_name ^ "(" ^ plist ^ ")" ]
          @ body_norm
          @ [ "end"; "set $" ^ var ^ " = make-fun-ref(" ^ light_escape_string fun_name ^ ")" ]
        in
        let acc = List.fold_left (fun a l -> l :: a) acc extra in
        loop next_i stack tmp_id acc
      else if line = "end" then
        (match stack with
        | LightIf n :: rest ->
          let rec add_extra acc n =
            if n <= 0 then acc else add_extra ("end" :: acc) (n - 1)
          in
          let acc = add_extra ("end" :: acc) n in
          loop (i + 1) rest tmp_id acc
        | _ :: rest ->
          loop (i + 1) rest tmp_id ("end" :: acc)
        | [] ->
          loop (i + 1) [] tmp_id ("end" :: acc))
      else if line = "else" || line = "break" || line = "continue" then
        loop (i + 1) stack tmp_id (line :: acc)
      else if re_matches re_light_return line then
        let expr = try String.trim (Str.matched_group 2 line) with Not_found -> "" in
        let out =
          if expr = "" then "return()"
          else "return(" ^ maybe_normalize_light_expr expr ^ ")"
        in
        loop (i + 1) stack tmp_id (out :: acc)
      else if re_matches re_light_let_def line then
        let kw = Str.matched_group 1 line in
        let name = Str.matched_group 2 line in
        let expr = Str.matched_group 3 line in
        loop (i + 1) stack tmp_id ((kw ^ " $" ^ name ^ " = " ^ maybe_normalize_light_expr expr) :: acc)
      else if re_matches re_light_index_assign line then
        let target = Str.matched_group 1 line in
        let idx_expr = Str.matched_group 2 line in
        let value_expr = Str.matched_group 3 line in
        let out =
          "set-index(" ^ maybe_normalize_light_expr target ^ ", "
          ^ maybe_normalize_light_expr idx_expr ^ ", "
          ^ maybe_normalize_light_expr value_expr ^ ")"
        in
        loop (i + 1) stack tmp_id (out :: acc)
      else if re_matches re_light_assign line then
        let name = Str.matched_group 1 line in
        let expr = Str.matched_group 2 line in
        loop (i + 1) stack tmp_id (("set $" ^ name ^ " = " ^ maybe_normalize_light_expr expr) :: acc)
      (* Case A: name(...) — no space before paren (space rule) *)
      else if re_matches re_light_call_no_space line then
        let head = Str.matched_group 1 line in
        let light_control_keywords =
          [ "if"; "elif"; "while"; "foreach"; "when"; "unless"; "switch"; "fori" ] in
        let light_all_keywords =
          [ "if"; "elif"; "else"; "while"; "foreach"; "def"; "let"; "defun"; "fun";
            "return"; "break"; "continue"; "end"; "alias"; "global"; "when"; "unless";
            "switch"; "case"; "fori"; "set"; "rec"; "sub"; "defn" ] in
        if List.mem head light_control_keywords then
          failwith ("Syntax error: '" ^ head ^ "(...)' is not allowed — use '" ^ head ^ " ...' with a space")
        else if List.mem head light_all_keywords then
          loop (i + 1) stack tmp_id (raw :: acc)
        else begin
          let after_head = String.sub line (String.length head) (String.length line - String.length head) in
          match (try Some (extract_balanced_parens after_head) with Failure _ -> None) with
          | Some (inner, rest) when String.trim rest = "" ->
            let candidate = head ^ "(" ^ inner ^ ")" in
            if light_safe_call_candidate candidate then begin
              let cls = light_classify_parens inner in
              if cls = "expr" && has_infix_ops_at_depth0 inner then
                failwith ("Space rule: use '" ^ head ^ " (" ^ inner ^ ")' instead of '" ^ head ^ "(" ^ inner ^ ")' for infix expressions");
              loop (i + 1) stack tmp_id (maybe_normalize_light_expr candidate :: acc)
            end else
              loop (i + 1) stack tmp_id (raw :: acc)
          | _ ->
            loop (i + 1) stack tmp_id (raw :: acc)
        end
      (* Case B: name tail — space after name (command mode, args collected) *)
      else if re_matches re_light_bare_call line then
        let head = Str.matched_group 1 line in
        let tail = Str.matched_group 2 line in
        let light_all_keywords =
          [ "if"; "elif"; "else"; "while"; "foreach"; "def"; "let"; "defun"; "fun";
            "return"; "break"; "continue"; "end"; "alias"; "global"; "when"; "unless";
            "switch"; "case"; "fori"; "set"; "rec"; "sub"; "defn" ] in
        if List.mem head light_all_keywords then
          loop (i + 1) stack tmp_id (raw :: acc)
        else
          let whole = head ^ " " ^ tail in
          if light_safe_call_candidate whole then begin
            let args = light_collect_args tail in
            let normed = List.map maybe_normalize_light_expr args in
            loop (i + 1) stack tmp_id ((head ^ "(" ^ String.concat ", " normed ^ ")") :: acc)
          end else
            loop (i + 1) stack tmp_id (raw :: acc)
      else
        loop (i + 1) stack tmp_id (raw :: acc)
  in
  loop 0 [] 0 []

(* ============================================================
   compile / eval / execute
   ============================================================ *)

type block_term =
  | Block_end
  | Block_else
  | Block_case

let parse_prefixed_symbol expr prefix =
  let len = String.length expr in
  if len > 1 && expr.[0] = prefix then
    let token = String.sub expr 1 (len - 1) in
    split_qualified_symbol token
  else
    None

let find_top_level_arrow s =
  let len = String.length s in
  let depth = ref 0 in
  let in_quote = ref false in
  let escaped = ref false in
  let found = ref None in
  let i = ref 0 in
  while !i < len - 1 && !found = None do
    let ch = s.[!i] in
    if !in_quote then begin
      if !escaped then
        escaped := false
      else if ch = '\\' then
        escaped := true
      else if ch = '"' then
        in_quote := false
    end else if ch = '"' then
      in_quote := true
    else begin
      if ch = '(' || ch = '[' || ch = '{' then incr depth
      else if ch = ')' || ch = ']' || ch = '}' then decr depth
      else if !depth = 0 && ch = '-' && s.[!i + 1] = '>' then
        found := Some !i
    end;
    incr i
  done;
  !found

let rec compile_expr raw_expr =
  let expr = String.trim raw_expr in
  if is_string_literal expr then
    EString (String.sub expr 1 (String.length expr - 2))
  else if re_matches re_number expr then
    ENum (float_of_string expr)
  else if expr = "nil" then
    ENil
  else if String.length expr > 1 && expr.[0] = '$' then begin
    match parse_prefixed_symbol expr '$' with
    | Some (module_name, name) ->
      if is_global_name name || is_local_name name then
        EVar (module_name, name)
      else
        failwith ("Invalid local variable name '$" ^ name ^ "' (locals must be lowercase)")
    | None ->
      failwith ("Cannot evaluate expression: '" ^ expr ^ "'")
  end
  else if String.length expr > 1 && expr.[0] = '@' then begin
    match parse_prefixed_symbol expr '@' with
    | Some (module_name, name) ->
      if is_global_name name || is_local_name name then
        EArrVar (module_name, name)
      else
        failwith ("Invalid local array name '@" ^ name ^ "' (locals must be lowercase)")
    | None ->
      failwith ("Cannot evaluate expression: '" ^ expr ^ "'")
  end
  else if String.length expr > 1 && expr.[0] = '%' then begin
    match parse_prefixed_symbol expr '%' with
    | Some (module_name, name) ->
      if is_global_name name || is_local_name name then
        EDictVar (module_name, name)
      else
        failwith ("Invalid local dict name '%" ^ name ^ "' (locals must be lowercase)")
    | None ->
      failwith ("Cannot evaluate expression: '" ^ expr ^ "'")
  end
  else if String.length expr >= 2 && expr.[0] = '[' && expr.[String.length expr - 1] = ']' then
    let inner = String.sub expr 1 (String.length expr - 2) in
    let items = parse_arglist inner in
    EArrayLit (List.map compile_expr items)
  else if String.length expr >= 2 && expr.[0] = '{' && expr.[String.length expr - 1] = '}' then
    let inner = String.sub expr 1 (String.length expr - 2) in
    let trimmed = String.trim inner in
    if String.length trimmed > 0 && trimmed.[0] = '$' then begin
      match find_top_level_arrow trimmed with
      | Some _ ->
        compile_lambda_expr trimmed
      | None ->
        let items =
          List.map (fun pair ->
            let pair = String.trim pair in
            match split_dict_pair pair with
            | None -> failwith ("Bad dict entry: '" ^ pair ^ "'")
            | Some (kexpr, vexpr) ->
              let kexpr = String.trim kexpr in
              let vexpr = String.trim vexpr in
              let key =
                if is_symbol_name kexpr then
                  DictKeySymbol kexpr
                else
                  DictKeyExpr (compile_expr kexpr)
              in
              (key, compile_expr vexpr)
          ) (parse_arglist inner)
        in
        EDictLit items
    end else begin
    let items =
      List.map (fun pair ->
        let pair = String.trim pair in
        match split_dict_pair pair with
        | None -> failwith ("Bad dict entry: '" ^ pair ^ "'")
        | Some (kexpr, vexpr) ->
          let kexpr = String.trim kexpr in
          let vexpr = String.trim vexpr in
          let key =
            if is_symbol_name kexpr then
              DictKeySymbol kexpr
            else
              DictKeyExpr (compile_expr kexpr)
          in
          (key, compile_expr vexpr)
      ) (parse_arglist inner)
    in
    EDictLit items
    end
  else if re_matches re_regex_lit expr then
    let pat = Str.matched_group 1 expr in
    ERegex (Pcre.regexp pat)
  else
    match parse_func_call expr with
    | Some ("fun", raw_args) ->
      compile_lambda_expr raw_args
    | Some (fname, raw_args) ->
      let args = parse_arglist raw_args in
      ECall (fname, List.map compile_expr args)
    | None ->
      failwith ("Cannot evaluate expression: '" ^ expr ^ "'")

and compile_lambda_expr raw =
  let trimmed = String.trim raw in
  let len = String.length trimmed in
  let arrow_pos =
    match find_top_level_arrow trimmed with
    | Some i -> i
    | None -> failwith "fun: missing ->"
  in
  let params_str = String.trim (String.sub trimmed 0 arrow_pos) in
  let body_str = String.trim (String.sub trimmed (arrow_pos + 2) (len - arrow_pos - 2)) in
  let param_parts =
    if params_str = "" then []
    else String.split_on_char ',' params_str
  in
  if param_parts = [] then
    failwith "fun: expected at least one parameter";
  let params = List.map (fun p ->
    let p = String.trim p in
    if String.length p > 1 && p.[0] = '$' then
      let name = String.sub p 1 (String.length p - 1) in
      if not (is_local_name name) then
        failwith ("fun: invalid parameter '$" ^ name ^ "' (locals must be lowercase)");
      name
    else
      failwith ("fun: bad parameter '" ^ p ^ "'")
  ) param_parts in
  ELambda (params, compile_expr body_str)

let rec compile_switch lines start switch_line =
  let len = Array.length lines in
  let rec skip_non_code i =
    if i >= len then i
    else if is_blank_or_comment (String.trim lines.(i)) then skip_non_code (i + 1)
    else i
  in
  let rec parse_cases i cases_rev =
    let i = skip_non_code i in
    if i >= len then
      failwith (Printf.sprintf "switch without matching end on line %d" switch_line);
    let line = String.trim lines.(i) in
    if re_matches re_case line then begin
      let cexpr = compile_expr (Str.matched_group 1 line) in
      let case_body, next_i, term = compile_block lines (i + 1) true true in
      let cases_rev = (cexpr, case_body) :: cases_rev in
      match term with
      | Some Block_case ->
        parse_cases next_i cases_rev
      | Some Block_else ->
        let else_body, after_else, term2 = compile_block lines next_i false false in
        (match term2 with
        | Some Block_end ->
          (List.rev cases_rev, else_body, after_else)
        | _ ->
          failwith (Printf.sprintf "switch without matching end on line %d" switch_line))
      | Some Block_end ->
        (List.rev cases_rev, [], next_i)
      | None ->
        failwith (Printf.sprintf "switch without matching end on line %d" switch_line)
    end else if is_else line then begin
      let else_body, next_i, term = compile_block lines (i + 1) false false in
      match term with
      | Some Block_end ->
        (List.rev cases_rev, else_body, next_i)
      | Some Block_case ->
        failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
      | _ ->
        failwith (Printf.sprintf "switch without matching end on line %d" switch_line)
    end else if is_end line then
      (List.rev cases_rev, [], i + 1)
    else
      failwith (Printf.sprintf "switch expects case/else/end on line %d" (i + 1))
  in
  parse_cases start []

and compile_block lines start allow_else allow_case =
  let len = Array.length lines in
  let rec loop i acc =
    if i >= len then
      (List.rev acc, i, None)
    else
      let line = String.trim lines.(i) in
      if is_blank_or_comment line then
        loop (i + 1) acc
      else if re_matches re_case line then
        if allow_case then
          (List.rev acc, i, Some Block_case)
        else
          failwith (Printf.sprintf "case without matching switch on line %d" (i + 1))
      else if is_else line then
        if allow_else then
          (List.rev acc, i + 1, Some Block_else)
        else
          failwith (Printf.sprintf "else without matching if on line %d" (i + 1))
      else if is_end line then
        (List.rev acc, i + 1, Some Block_end)
      else if re_matches re_global_decl line then
        let name = Str.matched_group 1 line in
        let raw_mod =
          try Some (Str.matched_group 3 line)
          with Not_found -> None
        in
        let where = Printf.sprintf "line %d" (i + 1) in
        let spec =
          try parse_global_decl_modifier raw_mod
          with Failure msg -> failwith (where ^ ": " ^ msg)
        in
        let default_expr =
          match spec.default_expr with
          | Some e when spec.has_default -> Some (compile_expr e)
          | _ -> None
        in
        loop (i + 1) (NGlobalDecl (i + 1, name, spec, default_expr) :: acc)
      else if re_matches re_set_var line then
        let name = Str.matched_group 2 line in
        let expr = Str.matched_group 3 line in
        loop (i + 1) (NSetVar (i + 1, name, compile_expr expr) :: acc)
      else if re_matches re_global_set line then
        let name = Str.matched_group 1 line in
        let expr = Str.matched_group 2 line in
        loop (i + 1) (NGlobalSet (i + 1, name, compile_expr expr) :: acc)
      else if re_matches re_set_arr line then
        let name = Str.matched_group 2 line in
        let expr = Str.matched_group 3 line in
        loop (i + 1) (NSetArr (i + 1, name, compile_expr expr) :: acc)
      else if re_matches re_set_dict line then
        let name = Str.matched_group 2 line in
        let expr = Str.matched_group 3 line in
        loop (i + 1) (NSetDict (i + 1, name, compile_expr expr) :: acc)
      else if re_matches re_return line then
        let raw = Str.matched_group 1 line in
        let rexpr = if String.trim raw = "" then None else Some (compile_expr raw) in
        loop (i + 1) (NReturn (i + 1, rexpr) :: acc)
      else if re_matches re_if line then
        let cond = Str.matched_group 1 line in
        let cexpr = compile_expr cond in
        let true_body, next_i, term = compile_block lines (i + 1) true false in
        begin
          match term with
          | Some Block_end ->
            loop next_i (NIf (i + 1, cexpr, true_body, []) :: acc)
          | Some Block_else ->
            let false_body, after_false, term2 = compile_block lines next_i false false in
            (match term2 with
            | Some Block_end ->
              loop after_false (NIf (i + 1, cexpr, true_body, false_body) :: acc)
            | Some Block_case ->
              failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
            | _ ->
              failwith (Printf.sprintf "if without matching end on line %d" (i + 1)))
          | Some Block_case ->
            failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
          | None ->
            failwith (Printf.sprintf "if without matching end on line %d" (i + 1))
        end
      else if re_matches re_when line then
        let cond = Str.matched_group 1 line in
        let cexpr = compile_expr cond in
        let true_body, next_i, term = compile_block lines (i + 1) true false in
        begin
          match term with
          | Some Block_end ->
            loop next_i (NIf (i + 1, cexpr, true_body, []) :: acc)
          | Some Block_else ->
            let false_body, after_false, term2 = compile_block lines next_i false false in
            (match term2 with
            | Some Block_end ->
              loop after_false (NIf (i + 1, cexpr, true_body, false_body) :: acc)
            | Some Block_case ->
              failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
            | _ ->
              failwith (Printf.sprintf "when without matching end on line %d" (i + 1)))
          | Some Block_case ->
            failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
          | None ->
            failwith (Printf.sprintf "when without matching end on line %d" (i + 1))
        end
      else if re_matches re_unless line then
        let cond = Str.matched_group 1 line in
        let cexpr = compile_expr cond in
        let true_body, next_i, term = compile_block lines (i + 1) true false in
        begin
          match term with
          | Some Block_end ->
            loop next_i (NUnless (i + 1, cexpr, true_body, []) :: acc)
          | Some Block_else ->
            let false_body, after_false, term2 = compile_block lines next_i false false in
            (match term2 with
            | Some Block_end ->
              loop after_false (NUnless (i + 1, cexpr, true_body, false_body) :: acc)
            | Some Block_case ->
              failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
            | _ ->
              failwith (Printf.sprintf "unless without matching end on line %d" (i + 1)))
          | Some Block_case ->
            failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
          | None ->
            failwith (Printf.sprintf "unless without matching end on line %d" (i + 1))
        end
      else if re_matches re_while line then
        let cond = Str.matched_group 1 line in
        let cexpr = compile_expr cond in
        let body, next_i, term = compile_block lines (i + 1) false false in
        (match term with
        | Some Block_end ->
          loop next_i (NWhile (i + 1, cexpr, body) :: acc)
        | Some Block_case ->
          failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
        | _ ->
          failwith (Printf.sprintf "while without matching end on line %d" (i + 1)))
      else if re_matches re_switch line then
        let switch_expr = compile_expr (Str.matched_group 1 line) in
        let cases, else_body, next_i = compile_switch lines (i + 1) (i + 1) in
        loop next_i (NSwitch (i + 1, switch_expr, cases, else_body) :: acc)
      else if re_matches re_sub_def line then
        let kind = Str.matched_group 1 line in
        let name = Str.matched_group 2 line in
        if not (is_symbol_name name) then
          failwith (Printf.sprintf "Syntax error on line %d: %s" (i + 1) line);
        let raw_params = Str.matched_group 3 line in
        let params =
          list_filter_map (fun s ->
            let p = String.trim s in
            if p = "" then None
            else
              let p =
                if String.length p > 0 && p.[0] = '$' then
                  String.sub p 1 (String.length p - 1)
                else
                  p
              in
              if not (is_local_name p) then
                  failwith ("Invalid parameter name '$" ^ p ^ "' (locals must be lowercase)");
              Some p
          ) (String.split_on_char ',' raw_params)
        in
        let body, next_i, term = compile_block lines (i + 1) false false in
        (match term with
        | Some Block_end ->
          loop next_i (NSubDef (i + 1, name, params, body, kind = "rec") :: acc)
        | Some Block_case ->
          failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
        | _ ->
          failwith (Printf.sprintf "%s without matching end on line %d" kind (i + 1)))
      else if re_matches re_alias line then
        let new_name = Str.matched_group 1 line in
        let old_name = Str.matched_group 2 line in
        if not (is_symbol_name new_name) then
          failwith (Printf.sprintf "Syntax error on line %d: %s" (i + 1) line);
        loop (i + 1) (NAlias (i + 1, new_name, old_name) :: acc)
      else if re_matches re_foreach line then
        let var = Str.matched_group 1 line in
        let arrname = Str.matched_group 2 line in
        if not (is_global_name var || is_local_name var) then
          failwith ("Invalid local variable name '$" ^ var ^ "' (locals must be lowercase)");
        let body, next_i, term = compile_block lines (i + 1) false false in
        (match term with
        | Some Block_end ->
          loop next_i (NForeach (i + 1, var, arrname, body) :: acc)
        | Some Block_case ->
          failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
        | _ ->
          failwith (Printf.sprintf "foreach without matching end on line %d" (i + 1)))
      else if re_matches re_fori line then
        let var = Str.matched_group 1 line in
        let arrname = Str.matched_group 2 line in
        if not (is_global_name var || is_local_name var) then
          failwith ("Invalid local variable name '$" ^ var ^ "' (locals must be lowercase)");
        let body, next_i, term = compile_block lines (i + 1) false false in
        (match term with
        | Some Block_end ->
          loop next_i (NFori (i + 1, var, arrname, body) :: acc)
        | Some Block_case ->
          failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
        | _ ->
          failwith (Printf.sprintf "fori without matching end on line %d" (i + 1)))
      else if line = "break" then
        loop (i + 1) (NBreak (i + 1) :: acc)
      else if line = "continue" then
        loop (i + 1) (NContinue (i + 1) :: acc)
      else if re_matches re_bare_call line then
        loop (i + 1) (NCall (i + 1, compile_expr line) :: acc)
      else
        failwith (Printf.sprintf "Syntax error on line %d: %s" (i + 1) line)
  in
  loop start []

let compile_program lines =
  let normalized = normalize_light_program lines in
  let arr = Array.of_list normalized in
  let nodes, next_i, term = compile_block arr 0 false false in
  match term with
  | None -> nodes
  | Some Block_else ->
    failwith (Printf.sprintf "else without matching if on line %d" next_i)
  | Some Block_case ->
    failwith (Printf.sprintf "case without matching switch on line %d" (next_i + 1))
  | Some Block_end ->
    failwith (Printf.sprintf "end without matching block on line %d" next_i)

let run_nodes_ref : (node list -> unit) ref = ref (fun _ -> ())
let invoke_lambda_ref : (value -> value list -> value) ref =
  ref (fun _ _ -> failwith "expected a function")

let invoke_named_sub target_module sub_name evaled =
  let sub = Hashtbl.find (module_subs_ref target_module) sub_name in
  let call_id = target_module ^ "/" ^ sub_name in
  let active_count =
    match hashtbl_find_opt active_calls call_id with
    | Some n -> n
    | None -> 0
  in
  if active_count > 0 && not sub.recursive then
    failwith (with_line_context ("recursion is not allowed for function '" ^ sub_name ^ "'; declare it with rec"));
  let saved_depth = !call_depth in
  if saved_depth + 1 > max_call_depth then
    failwith
      (with_line_context
         (Printf.sprintf
            "maximum call depth exceeded (%d); set SHELM_MAX_CALL_DEPTH to override (legacy: SUP_MAX_CALL_DEPTH)"
            max_call_depth));
  let saved_returning = !returning in
  let saved_module = !current_module in
  push_module_var_frame target_module;
  call_stack := call_id :: !call_stack;
  Hashtbl.replace active_calls call_id (active_count + 1);
  let restore () =
    call_stack :=
      (match !call_stack with
      | _ :: tl -> tl
      | [] -> []);
    let count =
      match hashtbl_find_opt active_calls call_id with
      | Some n -> n - 1
      | None -> 0
    in
    if count > 0 then Hashtbl.replace active_calls call_id count
    else Hashtbl.remove active_calls call_id;
    pop_module_var_frame target_module;
    call_depth := saved_depth;
    returning := saved_returning;
    current_module := saved_module
  in
  call_depth := !call_depth + 1;
  returning := false;
  current_module := target_module;
  (try
     let rec bind_params params values =
       match params with
       | [] -> ()
       | p :: ps ->
         let v, vs =
           match values with
           | [] -> (Nil, [])
           | x :: xs -> (x, xs)
         in
         module_var_set target_module p v;
         bind_params ps vs
     in
     bind_params sub.params evaled;
     module_var_remove_top target_module "_return";
     !run_nodes_ref sub.body;
     let ret =
       match module_var_find_top target_module "_return" with
       | Some v -> v
       | None -> Nil
     in
     restore ();
     ret
   with exn ->
     restore ();
     raise exn)

let rec eval_expr = function
  | EString raw ->
    parse_string_literal raw
  | ENum f ->
    Num f
  | ENil ->
    Nil
  | EVar (Some module_name, name) ->
    if is_global_name name then
      (require_declared_global name "expression" "read";
      get_global_var name)
    else if is_local_name name then
      get_module_var module_name name
    else
      failwith ("Invalid local variable name '$" ^ name ^ "' (locals must be lowercase)")
  | EVar (None, name) ->
    if is_global_name name then
      (require_declared_global name "expression" "read";
      get_global_var name)
    else if is_local_name name then
      (match module_var_lookup !current_module name with
      | Some v -> v
      | None -> get_global_var name)
    else
      failwith ("Invalid local variable name '$" ^ name ^ "' (locals must be lowercase)")
  | EArrVar (Some module_name, name) ->
    if is_global_name name then
      (require_declared_global name "expression" "read";
      get_global_array name)
    else if is_local_name name then
      get_module_array module_name name
    else
      failwith ("Invalid local array name '@" ^ name ^ "' (locals must be lowercase)")
  | EArrVar (None, name) ->
    if is_global_name name then
      (require_declared_global name "expression" "read";
      get_global_array name)
    else if is_local_name name then
      get_module_array !current_module name
    else
      failwith ("Invalid local array name '@" ^ name ^ "' (locals must be lowercase)")
  | EDictVar (Some module_name, name) ->
    if is_global_name name then
      (require_declared_global name "expression" "read";
      get_global_dict name)
    else if is_local_name name then
      get_module_dict module_name name
    else
      failwith ("Invalid local dict name '%" ^ name ^ "' (locals must be lowercase)")
  | EDictVar (None, name) ->
    if is_global_name name then
      (require_declared_global name "expression" "read";
      get_global_dict name)
    else if is_local_name name then
      get_module_dict !current_module name
    else
      failwith ("Invalid local dict name '%" ^ name ^ "' (locals must be lowercase)")
  | EArrayLit items ->
    Arr (dynarr_of_list (List.map eval_expr items))
  | EDictLit items ->
    let h = Hashtbl.create 8 in
    List.iter (fun (k, vexpr) ->
      let key =
        match k with
        | DictKeySymbol s -> s
        | DictKeyExpr e -> to_str (eval_expr e)
      in
      Hashtbl.replace h key (eval_expr vexpr)
    ) items;
    Dict h
  | ERegex rex ->
    Rex rex
  | ELambda (params, body) ->
    Lambda (params, body)
  | ECall (fname, args) ->
    let evaled = List.map eval_expr args in
    if fname = "print" then begin
      let parts, to_stderr =
        match split_last evaled with
        | prefix, Some last when prefix <> [] && to_str last = "1" -> (prefix, true)
        | _ -> (evaled, false)
      in
      let out = String.concat "" (List.map to_str parts) in
      if to_stderr then Printf.eprintf "%s\n" out else Printf.printf "%s\n" out;
      Str out
    end else (
      match resolve_sub_target fname with
      | Some (target_module, sub_name) ->
        invoke_named_sub target_module sub_name evaled
      | None ->
        if Hashtbl.mem builtins fname then
          (try
             (Hashtbl.find builtins fname) evaled
           with exn ->
             let msg =
               match exn with
               | Failure m -> m
               | Sys_error m -> m
               | _ -> Printexc.to_string exn
             in
             failwith (with_line_context msg))
        else
          match module_var_lookup !current_module fname with
          | Some fn ->
            (match fn with
            | Lambda _ | LambdaSub _ -> (!invoke_lambda_ref) fn evaled
            | _ -> failwith (with_line_context ("Unknown function: " ^ fname)))
          | None ->
            failwith (with_line_context ("Unknown function: " ^ fname))
    )

and exec_node = function
  | NGlobalDecl (line_no, name, spec, default_expr) ->
    let where = Printf.sprintf "line %d" line_no in
    declare_global_spec name spec where;
    (match default_expr with
    | Some expr when spec.has_default && not (Hashtbl.mem globals name) ->
      Hashtbl.replace globals name (eval_expr expr)
    | _ -> ())
  | NSetVar (line_no, name, expr) ->
    if is_global_name name then begin
      require_declared_global name (Printf.sprintf "line %d" line_no) "assignment";
      Hashtbl.replace globals name (eval_expr expr)
    end else if is_local_name name then
      module_var_set !current_module name (eval_expr expr)
    else
      failwith ("Invalid local variable name '$" ^ name ^ "' (locals must be lowercase)")
  | NGlobalSet (line_no, name, expr) ->
    if not (is_global_name name) then
      failwith ("Global names must be uppercase: '$" ^ name ^ "'");
    require_declared_global name (Printf.sprintf "line %d" line_no) "assignment";
    Hashtbl.replace globals name (eval_expr expr)
  | NSetArr (line_no, name, expr) ->
    if is_global_name name then begin
      require_declared_global name (Printf.sprintf "line %d" line_no) "assignment";
      Hashtbl.replace global_arrays name (eval_expr expr)
    end else if is_local_name name then
      Hashtbl.replace (module_arrays_ref !current_module) name (eval_expr expr)
    else
      failwith ("Invalid local array name '@" ^ name ^ "' (locals must be lowercase)")
  | NSetDict (line_no, name, expr) ->
    if is_global_name name then begin
      require_declared_global name (Printf.sprintf "line %d" line_no) "assignment";
      Hashtbl.replace global_dicts name (eval_expr expr)
    end else if is_local_name name then
      Hashtbl.replace (module_dicts_ref !current_module) name (eval_expr expr)
    else
      failwith ("Invalid local dict name '%" ^ name ^ "' (locals must be lowercase)")
  | NReturn (line_no, rexpr) ->
    if !call_depth <= 0 then
      failwith (Printf.sprintf "return outside function on line %d" line_no);
    let ret = match rexpr with Some e -> eval_expr e | None -> Nil in
    module_var_set !current_module "_return" ret;
    returning := true
  | NIf (_, cond_expr, true_body, false_body) ->
    let cond = eval_expr cond_expr in
    if is_truthy cond then run_nodes true_body else run_nodes false_body
  | NUnless (_, cond_expr, true_body, false_body) ->
    let cond = eval_expr cond_expr in
    if is_truthy cond then run_nodes false_body else run_nodes true_body
  | NWhile (_, cond_expr, body) ->
    let saved_depth = !loop_depth in
    loop_depth := saved_depth + 1;
    let rec run_loop () =
      if !returning then ()
      else if is_truthy (eval_expr cond_expr) then begin
        run_nodes body;
        if !returning then ()
        else if !breaking then breaking := false
        else if !continuing then (continuing := false; run_loop ())
        else run_loop ()
      end
    in
    (try
       run_loop ();
       loop_depth := saved_depth
     with exn ->
       loop_depth := saved_depth;
       raise exn)
  | NSwitch (_, switch_expr, cases, else_body) ->
    let switch_val = eval_expr switch_expr in
    let rec run_cases = function
      | [] -> run_nodes else_body
      | (case_expr, body) :: rest ->
        if to_str switch_val = to_str (eval_expr case_expr) then
          run_nodes body
        else
          run_cases rest
    in
    run_cases cases
  | NSubDef (_, name, params, body, recursive) ->
    Hashtbl.replace (module_subs_ref !current_module) name { params; body; recursive }
  | NAlias (_, new_name, old_name) ->
    if Hashtbl.mem builtins old_name then
      Hashtbl.replace builtins new_name (Hashtbl.find builtins old_name)
    else
      (match resolve_sub_target old_name with
      | Some (module_name, sub_name) ->
        Hashtbl.replace (module_subs_ref !current_module) new_name
          (Hashtbl.find (module_subs_ref module_name) sub_name)
      | None ->
        failwith ("alias: unknown function '" ^ old_name ^ "'"))
  | NForeach (line_no, var, arrname, body) ->
    if not (is_global_name var || is_local_name var) then
      failwith ("Invalid local variable name '$" ^ var ^ "' (locals must be lowercase)");
    let arr_val =
      match split_qualified_symbol arrname with
      | Some (Some module_name, name) ->
        if is_global_name name then
          (require_declared_global name "expression" "read";
          get_global_array name)
        else if is_local_name name then
          get_module_array module_name name
        else
          failwith ("Invalid local array name '@" ^ name ^ "' (locals must be lowercase)")
      | Some (None, name) ->
        if is_global_name name then
          (require_declared_global name "expression" "read";
          get_global_array name)
        else if is_local_name name then
          get_module_array !current_module name
        else
          failwith ("Invalid local array name '@" ^ name ^ "' (locals must be lowercase)")
      | None ->
        failwith (Printf.sprintf "Syntax error on line %d: foreach $%s @%s" line_no var arrname)
    in
    let arr_snapshot = match arr_val with
      | Arr r -> Array.sub r.data 0 r.len
      | _ -> [||]
    in
    let saved_depth = !loop_depth in
    loop_depth := saved_depth + 1;
    let rec run_each idx =
      if idx >= Array.length arr_snapshot || !returning then ()
      else begin
        let elem = arr_snapshot.(idx) in
        if is_global_name var then begin
          require_declared_global var (Printf.sprintf "line %d" line_no) "assignment";
          Hashtbl.replace globals var elem
        end else
          module_var_set !current_module var elem;
        run_nodes body;
        if !returning then ()
        else if !breaking then breaking := false
        else if !continuing then (continuing := false; run_each (idx + 1))
        else run_each (idx + 1)
      end
    in
    (try
       run_each 0;
       loop_depth := saved_depth
     with exn ->
       loop_depth := saved_depth;
       raise exn)
  | NFori (line_no, var, arrname, body) ->
    if not (is_global_name var || is_local_name var) then
      failwith ("Invalid local variable name '$" ^ var ^ "' (locals must be lowercase)");
    let arr_val =
      match split_qualified_symbol arrname with
      | Some (Some module_name, name) ->
        if is_global_name name then
          (require_declared_global name "expression" "read";
          get_global_array name)
        else if is_local_name name then
          get_module_array module_name name
        else
          failwith ("Invalid local array name '@" ^ name ^ "' (locals must be lowercase)")
      | Some (None, name) ->
        if is_global_name name then
          (require_declared_global name "expression" "read";
          get_global_array name)
        else if is_local_name name then
          get_module_array !current_module name
        else
          failwith ("Invalid local array name '@" ^ name ^ "' (locals must be lowercase)")
      | None ->
        failwith (Printf.sprintf "Syntax error on line %d: fori $%s @%s" line_no var arrname)
    in
    let arr_snapshot = match arr_val with
      | Arr r -> Array.sub r.data 0 r.len
      | _ -> [||]
    in
    let saved_depth = !loop_depth in
    loop_depth := saved_depth + 1;
    let rec run_each idx =
      if idx >= Array.length arr_snapshot || !returning then ()
      else begin
        let elem = arr_snapshot.(idx) in
        if is_global_name var then begin
          require_declared_global var (Printf.sprintf "line %d" line_no) "assignment";
          Hashtbl.replace globals var elem
        end else
          module_var_set !current_module var elem;
        module_var_set !current_module "i" (Num (float_of_int idx));
        run_nodes body;
        if !returning then ()
        else if !breaking then breaking := false
        else if !continuing then (continuing := false; run_each (idx + 1))
        else run_each (idx + 1)
      end
    in
    (try
       run_each 0;
       loop_depth := saved_depth
     with exn ->
       loop_depth := saved_depth;
       raise exn)
  | NBreak line_no ->
    if !loop_depth <= 0 then
      failwith (Printf.sprintf "break outside loop on line %d" line_no);
    breaking := true
  | NContinue line_no ->
    if !loop_depth <= 0 then
      failwith (Printf.sprintf "continue outside loop on line %d" line_no);
    continuing := true
  | NCall (_, expr) ->
    ignore (eval_expr expr)

and node_line_no = function
  | NGlobalDecl (line_no, _, _, _)
  | NSetVar (line_no, _, _)
  | NGlobalSet (line_no, _, _)
  | NSetArr (line_no, _, _)
  | NSetDict (line_no, _, _)
  | NReturn (line_no, _)
  | NIf (line_no, _, _, _)
  | NUnless (line_no, _, _, _)
  | NWhile (line_no, _, _)
  | NSwitch (line_no, _, _, _)
  | NSubDef (line_no, _, _, _, _)
  | NAlias (line_no, _, _)
  | NForeach (line_no, _, _, _)
  | NFori (line_no, _, _, _)
  | NBreak line_no
  | NContinue line_no
  | NCall (line_no, _) ->
    line_no

and run_nodes nodes =
  let rec loop = function
    | [] -> ()
    | _ when !returning || !breaking || !continuing -> ()
    | node :: rest ->
      let saved_line = !active_line_no in
      active_line_no := Some (node_line_no node);
      (try
         exec_node node;
         active_line_no := saved_line;
         loop rest
       with exn ->
         active_line_no := saved_line;
         raise exn)
  in
  loop nodes

let run_program lines =
  run_nodes (compile_program lines)

(* ============================================================
   register_builtins
   ============================================================ *)

let nth_str args n =
  match list_nth_opt args n with Some v -> to_str v | None -> ""

let nth_num args n =
  match list_nth_opt args n with Some v -> to_num v | None -> 0.0

let nth_val args n =
  match list_nth_opt args n with Some v -> v | None -> Nil

let require_arr fname = function
  | Arr r -> r
  | _ -> failwith (fname ^ ": first argument must be an array")

let require_dict fname = function
  | Dict h -> h
  | _ -> failwith (fname ^ ": first argument must be a dict")

let require_lambda fname = function
  | Lambda _ | LambdaSub _ -> ()
  | _ -> failwith (fname ^ ": argument must be a function")

let invoke_lambda fn args =
  match fn with
  | Lambda (params, body) ->
    let saved_depth = !call_depth in
    if saved_depth + 1 > max_call_depth then
      failwith
        (Printf.sprintf
           "maximum call depth exceeded (%d); set SHELM_MAX_CALL_DEPTH to override (legacy: SUP_MAX_CALL_DEPTH)"
           max_call_depth);
    push_module_var_frame !current_module;
    call_depth := saved_depth + 1;
    List.iteri (fun i p ->
      let v = if i < List.length args then List.nth args i else Nil in
      module_var_set !current_module p v
    ) params;
    let result = try eval_expr body with exn ->
      pop_module_var_frame !current_module;
      call_depth := saved_depth;
      raise exn in
    pop_module_var_frame !current_module;
    call_depth := saved_depth;
    result
  | LambdaSub (module_name, sub_name) ->
    invoke_named_sub module_name sub_name args
  | _ -> failwith "expected a function"

let () =
  invoke_lambda_ref := invoke_lambda

let status_to_code = function
  | Unix.WEXITED n -> n
  | Unix.WSIGNALED n -> 128 + n
  | Unix.WSTOPPED n -> 128 + n

let has_unsafe_shell_metacharacters s =
  let len = String.length s in
  let rec loop i =
    if i >= len then false
    else
      match s.[i] with
      | '|' | '&' | ';' | '<' | '>' | '`' | '$' | '\\' | '\n' -> true
      | _ -> loop (i + 1)
  in
  loop 0

let safe_close_fd fd =
  try Unix.close fd with Unix.Unix_error _ -> ()

let safe_remove_file path =
  try Sys.remove path with _ -> ()

let slurp_file path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let buf = Bytes.create n in
  really_input ic buf 0 n;
  close_in ic;
  Bytes.to_string buf

let slurp_file_capped ctx path =
  let st = Unix.stat path in
  if st.Unix.st_size > max_capture_bytes then
    failwith
      (Printf.sprintf
         "%s: captured output exceeds %d bytes (set SHELM_MAX_CAPTURE_BYTES to override; legacy: SUP_MAX_CAPTURE_BYTES)"
         ctx max_capture_bytes);
  slurp_file path

let normalize_command_argv ctx = function
  | Arr r ->
    let parts = List.map to_str (dynarr_to_list r) in
    if parts = [] then
      failwith (ctx ^ ": command array must not be empty");
    Array.of_list parts
  | _ ->
    failwith (ctx ^ ": command must be an array")

let re_timeout_seconds = Str.regexp {|^-?[0-9]+\(\.[0-9]+\)?$|}
let re_octal_mode = Str.regexp {|^0?[0-7]\{3,4\}$|}
let re_decimal_mode = Str.regexp {|^[0-9]+$|}

let parse_timeout_seconds timeout_opt ctx =
  match timeout_opt with
  | None -> None
  | Some raw ->
    let s = to_str raw in
    if not (re_matches re_timeout_seconds s) then
      failwith (ctx ^ ": timeout must be a positive number of seconds");
    let seconds = float_of_string s in
    if seconds <= 0.0 then
      failwith (ctx ^ ": timeout must be a positive number of seconds");
    Some seconds

let format_timeout_seconds seconds =
  let s = Printf.sprintf "%.3f" seconds in
  let rec trim i =
    if i < 0 then "0"
    else if s.[i] = '0' then trim (i - 1)
    else if s.[i] = '.' then String.sub s 0 i
    else String.sub s 0 (i + 1)
  in
  trim (String.length s - 1)

let sleep_seconds seconds =
  ignore (Unix.select [] [] [] seconds)

let pid_exists pid =
  try
    Unix.kill pid 0;
    true
  with
  | Unix.Unix_error (Unix.ESRCH, _, _) -> false
  | Unix.Unix_error _ -> true

let kill_pids_gracefully pids =
  if pids <> [] then begin
    List.iter
      (fun pid ->
        try Unix.kill pid Sys.sigterm
        with Unix.Unix_error (Unix.ESRCH, _, _) -> ())
      pids;
    let deadline = Unix.gettimeofday () +. 0.2 in
    let rec wait_term () =
      let alive = List.filter pid_exists pids in
      if alive = [] then ()
      else if Unix.gettimeofday () < deadline then begin
        sleep_seconds 0.01;
        wait_term ()
      end else
        List.iter
          (fun pid ->
            if pid_exists pid then
              try Unix.kill pid Sys.sigkill
              with Unix.Unix_error (Unix.ESRCH, _, _) -> ())
          alive
    in
    wait_term ()
  end

let wait_for_children pids timeout_s =
  let statuses : (int, Unix.process_status) Hashtbl.t = Hashtbl.create 16 in
  let record_blocking pid =
    try
      let _, status = Unix.waitpid [] pid in
      Hashtbl.replace statuses pid status
    with
    | Unix.Unix_error (Unix.ECHILD, _, _) ->
      Hashtbl.replace statuses pid (Unix.WEXITED 255)
  in
  let record_nonblocking pid =
    try
      let finished_pid, status = Unix.waitpid [Unix.WNOHANG] pid in
      if finished_pid = 0 then false
      else begin
        Hashtbl.replace statuses pid status;
        true
      end
    with
    | Unix.Unix_error (Unix.ECHILD, _, _) ->
      Hashtbl.replace statuses pid (Unix.WEXITED 255);
      true
  in
  match timeout_s with
  | None ->
    List.iter record_blocking pids;
    (statuses, false)
  | Some timeout ->
    let deadline = Unix.gettimeofday () +. timeout in
    let pending = ref pids in
    let rec loop () =
      pending := List.filter (fun pid -> not (record_nonblocking pid)) !pending;
      if !pending = [] then
        (statuses, false)
      else if Unix.gettimeofday () >= deadline then begin
        kill_pids_gracefully !pending;
        List.iter
          (fun pid ->
            if not (Hashtbl.mem statuses pid) then record_blocking pid)
          !pending;
        (statuses, true)
      end else begin
        sleep_seconds 0.01;
        loop ()
      end
    in
    loop ()

let command_result_dict ~code ~out ~err =
  let h = Hashtbl.create 3 in
  Hashtbl.replace h "code" (Num (float_of_int code));
  Hashtbl.replace h "out" (Str out);
  Hashtbl.replace h "err" (Str err);
  Dict h

let run_command_capture cmdv timeout_s =
  let cmd = normalize_command_argv "run" cmdv in
  let out_path = Filename.temp_file "shelm-run-out" ".tmp" in
  let err_path = Filename.temp_file "shelm-run-err" ".tmp" in
  let devnull_fd : Unix.file_descr option ref = ref None in
  let out_fd : Unix.file_descr option ref = ref None in
  let err_fd : Unix.file_descr option ref = ref None in
  let cleanup () =
    (match !devnull_fd with Some fd -> safe_close_fd fd | None -> ());
    (match !out_fd with Some fd -> safe_close_fd fd | None -> ());
    (match !err_fd with Some fd -> safe_close_fd fd | None -> ());
    devnull_fd := None;
    out_fd := None;
    err_fd := None;
    safe_remove_file out_path;
    safe_remove_file err_path
  in
  try
    devnull_fd := Some (Unix.openfile "/dev/null" [Unix.O_RDONLY] 0);
    out_fd := Some (Unix.openfile out_path [Unix.O_CREAT; Unix.O_TRUNC; Unix.O_WRONLY] 0o600);
    err_fd := Some (Unix.openfile err_path [Unix.O_CREAT; Unix.O_TRUNC; Unix.O_WRONLY] 0o600);
    let pid =
      Unix.create_process_env cmd.(0) cmd (Unix.environment ())
        (match !devnull_fd with Some fd -> fd | None -> assert false)
        (match !out_fd with Some fd -> fd | None -> assert false)
        (match !err_fd with Some fd -> fd | None -> assert false)
    in
    (match !devnull_fd with Some fd -> safe_close_fd fd | None -> ());
    (match !out_fd with Some fd -> safe_close_fd fd | None -> ());
    (match !err_fd with Some fd -> safe_close_fd fd | None -> ());
    devnull_fd := None;
    out_fd := None;
    err_fd := None;
    let statuses, timed_out = wait_for_children [pid] timeout_s in
    let status =
      match hashtbl_find_opt statuses pid with
      | Some s -> s
      | None -> Unix.WEXITED 1
    in
    let code = if timed_out then 124 else status_to_code status in
    let out = slurp_file_capped "run" out_path in
    let err =
      let base = slurp_file_capped "run" err_path in
      if timed_out then
        base ^ "run: timed out after " ^
        format_timeout_seconds (match timeout_s with Some x -> x | None -> 0.0) ^ "s\n"
      else
        base
    in
    cleanup ();
    command_result_dict ~code ~out ~err
  with exn ->
    cleanup ();
    raise exn

let run_pipeline_capture commands timeout_s =
  if commands = [] then
    failwith "pipe: command list must not be empty";
  let out_path = Filename.temp_file "shelm-pipe-out" ".tmp" in
  let err_path = Filename.temp_file "shelm-pipe-err" ".tmp" in
  let pids = ref [] in
  let last_pid = ref None in
  let prev_read = ref None in
  let close_prev_read () =
    match !prev_read with
    | Some fd ->
      safe_close_fd fd;
      prev_read := None
    | None -> ()
  in
  let cleanup_files () =
    close_prev_read ();
    safe_remove_file out_path;
    safe_remove_file err_path
  in
  try
    List.iteri (fun i cmd ->
      let next_pipe =
        if i < List.length commands - 1 then
          let r, w = Unix.pipe () in
          Some (r, w)
        else
          None
      in
      let stdin_fd =
        match !prev_read with
        | Some fd -> fd
        | None -> Unix.openfile "/dev/null" [Unix.O_RDONLY] 0
      in
      let stdout_fd =
        match next_pipe with
        | Some (_, w) -> w
        | None -> Unix.openfile out_path [Unix.O_CREAT; Unix.O_TRUNC; Unix.O_WRONLY] 0o600
      in
      let stderr_fd =
        Unix.openfile err_path [Unix.O_CREAT; Unix.O_APPEND; Unix.O_WRONLY] 0o600
      in
      try
        let pid =
          Unix.create_process_env cmd.(0) cmd (Unix.environment ()) stdin_fd stdout_fd stderr_fd
        in
        pids := pid :: !pids;
        last_pid := Some pid;
        safe_close_fd stderr_fd;
        safe_close_fd stdout_fd;
        (match !prev_read with
        | Some fd -> safe_close_fd fd
        | None -> safe_close_fd stdin_fd);
        prev_read :=
          (match next_pipe with
          | Some (r, _) -> Some r
          | None -> None)
      with exn ->
        safe_close_fd stderr_fd;
        safe_close_fd stdout_fd;
        safe_close_fd stdin_fd;
        (match next_pipe with
        | Some (r, _) -> safe_close_fd r
        | None -> ());
        raise exn
    ) commands;
    close_prev_read ();
    let statuses = Hashtbl.create 8 in
    let waited, timed_out = wait_for_children !pids timeout_s in
    Hashtbl.iter (fun pid status -> Hashtbl.replace statuses pid status) waited;
    let last_status =
      match !last_pid with
      | Some pid ->
        (match hashtbl_find_opt statuses pid with
        | Some status -> status
        | None -> Unix.WEXITED 1)
      | None -> Unix.WEXITED 1
    in
    let code = if timed_out then 124 else status_to_code last_status in
    let out = slurp_file_capped "pipe" out_path in
    let err =
      let base = slurp_file_capped "pipe" err_path in
      if timed_out then
        base ^ "pipe: timed out after " ^
        format_timeout_seconds (match timeout_s with Some x -> x | None -> 0.0) ^ "s\n"
      else
        base
    in
    cleanup_files ();
    command_result_dict ~code ~out ~err
  with exn ->
    if !pids <> [] then begin
      kill_pids_gracefully !pids;
      ignore (wait_for_children !pids (Some 0.2))
    end;
    cleanup_files ();
    raise exn

let dict_of_assoc pairs =
  let h = Hashtbl.create (max 8 (List.length pairs)) in
  List.iter (fun (k, v) -> Hashtbl.replace h k v) pairs;
  Dict h

let errno_code = function
  | Unix.EPERM -> 1
  | Unix.ENOENT -> 2
  | Unix.EACCES -> 13
  | Unix.EEXIST -> 17
  | Unix.ENOTDIR -> 20
  | Unix.EINVAL -> 22
  | Unix.ENOSYS -> 38
  | Unix.ENOTEMPTY -> 39
  | _ -> 1

let sys_ok fields =
  dict_of_assoc (("ok", Num 1.0) :: ("code", Num 0.0) :: ("err", Str "") :: fields)

let sys_err code err fields =
  let c = if code < 0 then 1 else code in
  dict_of_assoc
    (("ok", Num 0.0) :: ("code", Num (float_of_int c)) :: ("err", Str err) :: fields)

let sys_type_from_kind = function
  | Unix.S_REG -> "file"
  | Unix.S_DIR -> "dir"
  | Unix.S_LNK -> "link"
  | Unix.S_CHR -> "char"
  | Unix.S_BLK -> "block"
  | Unix.S_FIFO -> "fifo"
  | Unix.S_SOCK -> "socket"

let path_type path =
  try
    let st = Unix.lstat path in
    sys_type_from_kind st.Unix.st_kind
  with Unix.Unix_error _ ->
    "missing"

let sys_path_arg value =
  match value with
  | Arr _ | Dict _ | Rex _ -> None
  | _ ->
    let p = to_str value in
    if p = "" then None else Some p

let parse_mode_value = function
  | Num f when classify_float f <> FP_nan && classify_float f <> FP_infinite ->
    Some (int_of_float f)
  | Str s ->
    if re_matches re_octal_mode s then
      Some (int_of_string ("0o" ^ s))
    else if re_matches re_decimal_mode s then
      Some (int_of_string s)
    else
      None
  | _ -> None

let format_date_ymd tm =
  Printf.sprintf "%04d-%02d-%02d" (tm.Unix.tm_year + 1900) (tm.Unix.tm_mon + 1) tm.Unix.tm_mday

let format_time_iso tm =
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ"
    (tm.Unix.tm_year + 1900) (tm.Unix.tm_mon + 1) tm.Unix.tm_mday
    tm.Unix.tm_hour tm.Unix.tm_min tm.Unix.tm_sec

let register_builtins () =
  let add name f = Hashtbl.replace builtins name f in
  let sys_capabilities : (string, value list -> value) Hashtbl.t = Hashtbl.create 32 in
  let add_sys name f = Hashtbl.replace sys_capabilities name f in
  let stats_fields st =
    let mode = st.Unix.st_perm land 0o7777 in
    [
      ("type", Str (sys_type_from_kind st.Unix.st_kind));
      ("dev", Num (float_of_int st.Unix.st_dev));
      ("ino", Num (float_of_int st.Unix.st_ino));
      ("mode", Num (float_of_int mode));
      ("mode-oct", Str (Printf.sprintf "%04o" mode));
      ("nlink", Num (float_of_int st.Unix.st_nlink));
      ("uid", Num (float_of_int st.Unix.st_uid));
      ("gid", Num (float_of_int st.Unix.st_gid));
      ("rdev", Num (float_of_int st.Unix.st_rdev));
      ("size", Num (float_of_int st.Unix.st_size));
      ("atime", Num st.Unix.st_atime);
      ("mtime", Num st.Unix.st_mtime);
      ("ctime", Num st.Unix.st_ctime);
      ("blksize", Num 0.0);
      ("blocks", Num 0.0);
    ]
  in

  (* Math *)
  add "add" (fun a -> Num (nth_num a 0 +. nth_num a 1));
  add "sub" (fun a -> Num (nth_num a 0 -. nth_num a 1));
  add "mul" (fun a -> Num (nth_num a 0 *. nth_num a 1));
  add "div" (fun a ->
    let b = nth_num a 1 in
    if b = 0.0 then failwith "div: division by zero";
    Num (nth_num a 0 /. b));
  add "mod" (fun a ->
    let b = nth_num a 1 in
    if b = 0.0 then failwith "mod: division by zero";
    Num (mod_float (nth_num a 0) b));

  (* String *)
  add "concat" (fun a -> Str (nth_str a 0 ^ nth_str a 1));
  add "length" (fun a -> Num (float_of_int (String.length (nth_str a 0))));
  add "upper"  (fun a -> Str (String.uppercase_ascii (nth_str a 0)));
  add "lower"  (fun a -> Str (String.lowercase_ascii (nth_str a 0)));
  add "split"  (fun a ->
    let delim = nth_str a 0 in
    let str = nth_str a 1 in
    if delim = "" then Arr (dynarr_of_list [Str str])
    else begin
      let parts = ref [] in
      let dlen = String.length delim in
      let slen = String.length str in
      let start = ref 0 in
      let i = ref 0 in
      while !i <= slen - dlen do
        if String.sub str !i dlen = delim then begin
          parts := Str (String.sub str !start (!i - !start)) :: !parts;
          start := !i + dlen;
          i := !i + dlen
        end else
          incr i
      done;
      parts := Str (String.sub str !start (slen - !start)) :: !parts;
      Arr (dynarr_of_list (List.rev !parts))
    end);
  add "join" (fun a ->
    let delim = nth_str a 0 in
    let r = require_arr "join" (nth_val a 1) in
    Str (String.concat delim (List.map to_str (dynarr_to_list r))));

  (* Comparison *)
  add "eq" (fun a -> Num (if nth_str a 0 = nth_str a 1 then 1.0 else 0.0));
  add "gt" (fun a -> Num (if nth_num a 0 > nth_num a 1 then 1.0 else 0.0));
  add "lt" (fun a -> Num (if nth_num a 0 < nth_num a 1 then 1.0 else 0.0));
  add "ne" (fun a -> Num (if nth_str a 0 <> nth_str a 1 then 1.0 else 0.0));
  add "neq" (fun a -> Num (if nth_str a 0 <> nth_str a 1 then 1.0 else 0.0));
  add "ge" (fun a -> Num (if nth_num a 0 >= nth_num a 1 then 1.0 else 0.0));
  add "gte" (fun a -> Num (if nth_num a 0 >= nth_num a 1 then 1.0 else 0.0));
  add "le" (fun a -> Num (if nth_num a 0 <= nth_num a 1 then 1.0 else 0.0));
  add "lte" (fun a -> Num (if nth_num a 0 <= nth_num a 1 then 1.0 else 0.0));
  add "and" (fun a -> Num (if is_truthy (nth_val a 0) && is_truthy (nth_val a 1) then 1.0 else 0.0));
  add "or" (fun a -> Num (if is_truthy (nth_val a 0) || is_truthy (nth_val a 1) then 1.0 else 0.0));
  add "not" (fun a -> Num (if is_truthy (nth_val a 0) then 0.0 else 1.0));
  add "is-empty" (fun a ->
    let v = nth_val a 0 in
    Num (match v with Nil -> 1.0 | Str "" -> 1.0 | _ -> 0.0));
  add "true" (fun _ -> Num 1.0);
  add "false" (fun _ -> Num 0.0);

  (* Regex *)
  add "matchrx" (fun a ->
    let str = nth_str a 0 in
    let rex = match nth_val a 1 with
      | Rex r -> r
      | _ -> failwith "matchrx: second argument must be a regex #\"...\"" in
    Num (if Pcre.pmatch ~rex str then 1.0 else 0.0));
  add "extract" (fun a ->
    let str = nth_str a 0 in
    let rex = match nth_val a 1 with
      | Rex r -> r
      | _ -> failwith "extract: second argument must be a regex #\"...\"" in
    try
      let ss = Pcre.extract ~rex str in
      let caps = ref [] in
      for i = Array.length ss - 1 downto 1 do
        caps := Str ss.(i) :: !caps
      done;
	      Arr (dynarr_of_list !caps)
	    with Not_found -> Arr (dynarr_empty ()));
  add "rx-sub" (fun a ->
    let text = nth_str a 0 in
    let replacement = nth_str a 2 in
    let flags = nth_str a 3 in
    let rex =
      match nth_val a 1 with
      | Rex r -> r
      | v ->
        let pat = to_str v in
        let pcre_flags = ref [] in
        if String.contains flags 'i' then pcre_flags := `CASELESS :: !pcre_flags;
        if String.contains flags 'm' then pcre_flags := `MULTILINE :: !pcre_flags;
        if String.contains flags 's' then pcre_flags := `DOTALL :: !pcre_flags;
        (try Pcre.regexp ~flags:!pcre_flags pat
         with Pcre.Error _ ->
           failwith "rx-sub: invalid regex pattern")
    in
    try
      if String.contains flags 'g' then
        Str (Pcre.replace ~rex ~templ:replacement text)
      else
        Str (Pcre.replace_first ~rex ~templ:replacement text)
    with Pcre.Error _ ->
      failwith "rx-sub: invalid regex pattern");

  add "replace" (fun a ->
    let text = nth_str a 0 in
    let replacement = nth_str a 2 in
    let rex =
      match nth_val a 1 with
      | Rex r -> r
      | v ->
        (try Pcre.regexp (to_str v)
         with Pcre.Error _ -> failwith "replace: invalid regex pattern")
    in
    (try Str (Pcre.replace_first ~rex ~templ:replacement text)
     with Pcre.Error _ -> failwith "replace: invalid regex pattern"));

  add "replace-all" (fun a ->
    let text = nth_str a 0 in
    let replacement = nth_str a 2 in
    let rex =
      match nth_val a 1 with
      | Rex r -> r
      | v ->
        (try Pcre.regexp (to_str v)
         with Pcre.Error _ -> failwith "replace-all: invalid regex pattern")
    in
    (try Str (Pcre.replace ~rex ~templ:replacement text)
     with Pcre.Error _ -> failwith "replace-all: invalid regex pattern"));

  (* Array *)
  add "array" (fun a -> Arr (dynarr_of_list a));
  add "push" (fun a ->
    let r = require_arr "push" (nth_val a 0) in
    let rest =
      match a with
      | [] -> []
      | _ :: tl -> tl
    in
    List.iter (dynarr_push r) rest;
    Arr r);
  add "pop" (fun a ->
    let r = require_arr "pop" (nth_val a 0) in
    match dynarr_pop r with
    | Some v -> v
    | None -> Nil);
  add "get" (fun a ->
    match nth_val a 0 with
    | Arr r ->
      let idx = int_of_float (nth_num a 1) in
      (match dynarr_get r idx with Some v -> v | None -> Nil)
    | Dict h ->
      let key = nth_str a 1 in
      (match hashtbl_find_opt h key with Some v -> v | None -> Nil)
    | _ ->
      failwith "get: first argument must be an array");
  add "len" (fun a ->
    let r = require_arr "len" (nth_val a 0) in
    Num (float_of_int r.len));
  add "set-index" (fun a ->
    let idxv = nth_val a 1 in
    let value = nth_val a 2 in
    (match nth_val a 0 with
    | Arr r ->
      let idx = int_of_float (to_num idxv) in
      if idx < 0 then failwith "set-index: negative array index";
      dynarr_ensure_capacity r (idx + 1);
      if idx >= r.len then r.len <- idx + 1;
      r.data.(idx) <- value;
      value
    | Dict h ->
      Hashtbl.replace h (to_str idxv) value;
      value
    | _ ->
      failwith "set-index: first argument must be an array or dict"));

  (* Dict *)
  add "dict" (fun a ->
    let h = Hashtbl.create 8 in
    let rec fill = function
      | k :: v :: rest -> Hashtbl.replace h (to_str k) v; fill rest
      | _ -> () in
    fill a;
    Dict h);
  add "dict-get" (fun a ->
    let h = require_dict "dict-get" (nth_val a 0) in
    let key = nth_str a 1 in
    (match hashtbl_find_opt h key with Some v -> v | None -> Nil));
  add "dict-set" (fun a ->
    let h = require_dict "dict-set" (nth_val a 0) in
    let key = nth_str a 1 in
    let v = nth_val a 2 in
    Hashtbl.replace h key v; v);
  add "dict-keys" (fun a ->
    let h = require_dict "dict-keys" (nth_val a 0) in
    Arr (dynarr_of_list (Hashtbl.fold (fun k _ acc -> Str k :: acc) h [])));
  add "dict-has" (fun a ->
    let h = require_dict "dict-has" (nth_val a 0) in
    Num (if Hashtbl.mem h (nth_str a 1) then 1.0 else 0.0));
  add "dict-del" (fun a ->
    let h = require_dict "dict-del" (nth_val a 0) in
    let key = nth_str a 1 in
    let v = match hashtbl_find_opt h key with Some v -> v | None -> Nil in
    Hashtbl.remove h key; v);

  (* Array helpers *)
  add "sort" (fun a ->
    let r = require_arr "sort" (nth_val a 0) in
    let lst = dynarr_to_list r in
    let sorted = List.sort (fun a b -> compare (to_str a) (to_str b)) lst in
    Arr (dynarr_of_list sorted));
  add "reverse" (fun a ->
    let r = require_arr "reverse" (nth_val a 0) in
    Arr (dynarr_of_list (List.rev (dynarr_to_list r))));
  add "uniq" (fun a ->
    let r = require_arr "uniq" (nth_val a 0) in
    let seen = Hashtbl.create 16 in
    let out = List.filter (fun v ->
      let k = to_str v in
      if Hashtbl.mem seen k then false
      else (Hashtbl.replace seen k true; true)
    ) (dynarr_to_list r) in
    Arr (dynarr_of_list out));
  add "flatten" (fun a ->
    let r = require_arr "flatten" (nth_val a 0) in
    let out = ref [] in
    dynarr_iter (fun v ->
      match v with
      | Arr inner -> dynarr_iter (fun x -> out := x :: !out) inner
      | other -> out := other :: !out
    ) r;
    Arr (dynarr_of_list (List.rev !out)));
  add "zip" (fun a ->
    let r1 = require_arr "zip" (nth_val a 0) in
    let r2 = match nth_val a 1 with
      | Arr r -> r
      | _ -> failwith "zip: second argument must be an array" in
    let len = min r1.len r2.len in
    let out = ref [] in
    for i = len - 1 downto 0 do
      let v1 = match dynarr_get r1 i with Some v -> v | None -> Nil in
      let v2 = match dynarr_get r2 i with Some v -> v | None -> Nil in
      out := Arr (dynarr_of_list [v1; v2]) :: !out
    done;
    Arr (dynarr_of_list !out));
  add "take" (fun a ->
    let r = require_arr "take" (nth_val a 0) in
    let n = int_of_float (nth_num a 1) in
    let n = min n r.len in
    let out = ref [] in
    for i = n - 1 downto 0 do
      out := (match dynarr_get r i with Some v -> v | None -> Nil) :: !out
    done;
    Arr (dynarr_of_list !out));
  add "drop" (fun a ->
    let r = require_arr "drop" (nth_val a 0) in
    let n = int_of_float (nth_num a 1) in
    if n >= r.len then Arr (dynarr_empty ())
    else begin
      let out = ref [] in
      for i = r.len - 1 downto n do
        out := (match dynarr_get r i with Some v -> v | None -> Nil) :: !out
      done;
      Arr (dynarr_of_list !out)
    end);
  add "chunk" (fun a ->
    let r = require_arr "chunk" (nth_val a 0) in
    let n = int_of_float (nth_num a 1) in
    if n <= 0 then failwith "chunk: size must be positive";
    let lst = dynarr_to_list r in
    let rec aux acc chunk remaining count =
      match remaining with
      | [] -> if chunk = [] then List.rev acc else List.rev (Arr (dynarr_of_list (List.rev chunk)) :: acc)
      | x :: xs ->
        if count = n then
          aux (Arr (dynarr_of_list (List.rev chunk)) :: acc) [x] xs 1
        else
          aux acc (x :: chunk) xs (count + 1)
    in
    Arr (dynarr_of_list (aux [] [] lst 0)));
  add "range" (fun a ->
    let from_n = int_of_float (nth_num a 0) in
    let to_n = int_of_float (nth_num a 1) in
    let out = ref [] in
    if from_n <= to_n then
      for i = to_n downto from_n do out := Num (float_of_int i) :: !out done
    else
      for i = to_n to from_n do out := Num (float_of_int i) :: !out done;
    Arr (dynarr_of_list !out));
  add "sum" (fun a ->
    let r = require_arr "sum" (nth_val a 0) in
    let total = ref 0.0 in
    dynarr_iter (fun v -> total := !total +. to_num v) r;
    Num !total);
  add "min" (fun a ->
    let r = require_arr "min" (nth_val a 0) in
    if r.len = 0 then Nil
    else begin
      let m = ref (to_num (match dynarr_get r 0 with Some v -> v | None -> Nil)) in
      dynarr_iter (fun v -> let n = to_num v in if n < !m then m := n) r;
      Num !m
    end);
  add "max" (fun a ->
    let r = require_arr "max" (nth_val a 0) in
    if r.len = 0 then Nil
    else begin
      let m = ref (to_num (match dynarr_get r 0 with Some v -> v | None -> Nil)) in
      dynarr_iter (fun v -> let n = to_num v in if n > !m then m := n) r;
      Num !m
    end);

  (* Functional *)
  add "map" (fun a ->
    let r = require_arr "map" (nth_val a 0) in
    let _ = require_lambda "map" (nth_val a 1) in
    let fn = nth_val a 1 in
    Arr (dynarr_of_list (List.map (fun v -> invoke_lambda fn [v]) (dynarr_to_list r))));
  add "filter" (fun a ->
    let r = require_arr "filter" (nth_val a 0) in
    let _ = require_lambda "filter" (nth_val a 1) in
    let fn = nth_val a 1 in
    Arr (dynarr_of_list (List.filter (fun v -> is_truthy (invoke_lambda fn [v])) (dynarr_to_list r))));
  add "reject" (fun a ->
    let r = require_arr "reject" (nth_val a 0) in
    let _ = require_lambda "reject" (nth_val a 1) in
    let fn = nth_val a 1 in
    Arr (dynarr_of_list (List.filter (fun v -> not (is_truthy (invoke_lambda fn [v]))) (dynarr_to_list r))));
  add "reduce" (fun a ->
    let r = require_arr "reduce" (nth_val a 0) in
    let init = nth_val a 1 in
    let _ = require_lambda "reduce" (nth_val a 2) in
    let fn = nth_val a 2 in
    List.fold_left (fun acc v -> invoke_lambda fn [acc; v]) init (dynarr_to_list r));
  add "find" (fun a ->
    let r = require_arr "find" (nth_val a 0) in
    let _ = require_lambda "find" (nth_val a 1) in
    let fn = nth_val a 1 in
    let rec search = function
      | [] -> Nil
      | v :: rest -> if is_truthy (invoke_lambda fn [v]) then v else search rest
    in
    search (dynarr_to_list r));
  add "any" (fun a ->
    let r = require_arr "any" (nth_val a 0) in
    let _ = require_lambda "any" (nth_val a 1) in
    let fn = nth_val a 1 in
    let rec check = function
      | [] -> Num 0.0
      | v :: rest -> if is_truthy (invoke_lambda fn [v]) then Num 1.0 else check rest
    in
    check (dynarr_to_list r));
  add "all" (fun a ->
    let r = require_arr "all" (nth_val a 0) in
    let _ = require_lambda "all" (nth_val a 1) in
    let fn = nth_val a 1 in
    let rec check = function
      | [] -> Num 1.0
      | v :: rest -> if is_truthy (invoke_lambda fn [v]) then check rest else Num 0.0
    in
    check (dynarr_to_list r));
  add "none" (fun a ->
    let r = require_arr "none" (nth_val a 0) in
    let _ = require_lambda "none" (nth_val a 1) in
    let fn = nth_val a 1 in
    let rec check = function
      | [] -> Num 1.0
      | v :: rest -> if is_truthy (invoke_lambda fn [v]) then Num 0.0 else check rest
    in
    check (dynarr_to_list r));
  add "count" (fun a ->
    let r = require_arr "count" (nth_val a 0) in
    let _ = require_lambda "count" (nth_val a 1) in
    let fn = nth_val a 1 in
    let n = ref 0 in
    dynarr_iter (fun v -> if is_truthy (invoke_lambda fn [v]) then incr n) r;
    Num (float_of_int !n));
  add "each" (fun a ->
    let r = require_arr "each" (nth_val a 0) in
    let _ = require_lambda "each" (nth_val a 1) in
    let fn = nth_val a 1 in
    dynarr_iter (fun v -> ignore (invoke_lambda fn [v])) r;
    Arr r);
  add "flat-map" (fun a ->
    let r = require_arr "flat-map" (nth_val a 0) in
    let _ = require_lambda "flat-map" (nth_val a 1) in
    let fn = nth_val a 1 in
    let out = ref [] in
    dynarr_iter (fun v ->
      match invoke_lambda fn [v] with
      | Arr inner -> dynarr_iter (fun x -> out := x :: !out) inner
      | other -> out := other :: !out
    ) r;
    Arr (dynarr_of_list (List.rev !out)));
  add "make-fun-ref" (fun a ->
    let name = nth_str a 0 in
    if name = "" then failwith "make-fun-ref: missing function name";
    let subs = module_subs_ref !current_module in
    if not (Hashtbl.mem subs name) then
      failwith ("make-fun-ref: unknown function '" ^ name ^ "'");
    LambdaSub (!current_module, name));
  add "sort-by" (fun a ->
    let r = require_arr "sort-by" (nth_val a 0) in
    let _ = require_lambda "sort-by" (nth_val a 1) in
    let fn = nth_val a 1 in
    let lst = dynarr_to_list r in
    let sorted = List.sort (fun a b ->
      compare (to_str (invoke_lambda fn [a])) (to_str (invoke_lambda fn [b]))
    ) lst in
    Arr (dynarr_of_list sorted));
  add "group-by" (fun a ->
    let r = require_arr "group-by" (nth_val a 0) in
    let _ = require_lambda "group-by" (nth_val a 1) in
    let fn = nth_val a 1 in
    let h = Hashtbl.create 16 in
    dynarr_iter (fun v ->
      let key = to_str (invoke_lambda fn [v]) in
      let lst = match hashtbl_find_opt h key with
        | Some (Arr r) -> r
        | _ -> let r = dynarr_empty () in Hashtbl.replace h key (Arr r); r
      in
      dynarr_push lst v
    ) r;
    Dict h);
  add "uniq-by" (fun a ->
    let r = require_arr "uniq-by" (nth_val a 0) in
    let _ = require_lambda "uniq-by" (nth_val a 1) in
    let fn = nth_val a 1 in
    let seen = Hashtbl.create 16 in
    let out = List.filter (fun v ->
      let key = to_str (invoke_lambda fn [v]) in
      if Hashtbl.mem seen key then false
      else (Hashtbl.replace seen key true; true)
    ) (dynarr_to_list r) in
    Arr (dynarr_of_list out));
  add "apply" (fun a ->
    let _ = require_lambda "apply" (nth_val a 0) in
    let fn = nth_val a 0 in
    let args = match a with _ :: tl -> tl | [] -> [] in
    invoke_lambda fn args);

  (* File I/O *)
  add "save" (fun a ->
    let path = nth_str a 0 in
    let content = nth_str a 1 in
    if path = "" then failwith "save: missing filename";
    let oc = open_out path in
    output_string oc content;
    close_out oc;
    Str path);
  add "write-file" (fun a ->
    let text = nth_str a 0 in
    let path = nth_str a 1 in
    if path = "" then failwith "write-file: missing path";
    let oc = open_out path in
    output_string oc text;
    close_out oc;
    Str path);
  add "append-file" (fun a ->
    let text = nth_str a 0 in
    let path = nth_str a 1 in
    if path = "" then failwith "append-file: missing path";
    let oc = open_out_gen [Open_creat; Open_wronly; Open_append] 0o644 path in
    output_string oc text;
    close_out oc;
    Str path);
  add "read-file" (fun a ->
    let file = nth_str a 0 in
    if file = "" then failwith "read-file: missing filename";
    let ic = open_in file in
    let n = in_channel_length ic in
    let buf = Bytes.create n in
    really_input ic buf 0 n;
    close_in ic;
    Str (Bytes.to_string buf));
  add "write-lines-file" (fun a ->
    let r = require_arr "write-lines-file" (nth_val a 0) in
    let path = nth_str a 1 in
    if path = "" then failwith "write-lines-file: missing path";
    let oc = open_out path in
    dynarr_iter (fun v -> output_string oc (to_str v ^ "\n")) r;
    close_out oc;
    Str path);
  add "read-file-lines" (fun a ->
    let file = nth_str a 0 in
    if file = "" then failwith "read-file-lines: missing filename";
    let ic = open_in file in
    let lines = ref [] in
    (try while true do lines := input_line ic :: !lines done
     with End_of_file -> ());
    close_in ic;
    Arr (dynarr_of_list (List.rev_map (fun s -> Str s) !lines)));
  add "read-dir" (fun a ->
    let dir = nth_str a 0 in
    if dir = "" then failwith "read-dir: missing directory";
    let dh = Unix.opendir dir in
    let entries = ref [] in
    (try while true do
      let e = Unix.readdir dh in
      if e <> "." && e <> ".." then entries := Str e :: !entries
    done with End_of_file -> ());
    Unix.closedir dh;
    Arr (dynarr_of_list (List.rev !entries)));
  add "load" (fun a ->
    let file = nth_str a 0 in
    if file = "" then failwith "load: missing filename";
    let path = resolve_load_path file in
    let abs_path = canonicalize_path path in
    if Hashtbl.mem module_loading_paths abs_path then
      failwith ("load: cyclic dependency detected: " ^ format_load_cycle abs_path);
    if Hashtbl.mem loaded_module_paths abs_path then
      Str file
    else begin
    let ic = open_in abs_path in
    let lines = ref [] in
    (try while true do lines := input_line ic :: !lines done
     with End_of_file -> ());
    close_in ic;
    let module_name = module_name_from_file abs_path in
    (match hashtbl_find_opt module_source_paths module_name with
    | Some other when other <> abs_path ->
      failwith
        (Printf.sprintf "load: module name collision '%s' between '%s' and '%s'"
          module_name other abs_path)
    | _ -> ());
    Hashtbl.replace module_loading_paths abs_path true;
    module_load_stack := abs_path :: !module_load_stack;
    Hashtbl.replace module_source_paths module_name abs_path;
    Hashtbl.replace module_dirs module_name (Filename.dirname abs_path);
    ignore (module_vars_ref module_name);
    ignore (module_var_frames_ref module_name);
    ignore (module_arrays_ref module_name);
    ignore (module_dicts_ref module_name);
    ignore (module_subs_ref module_name);
    let saved_module = !current_module in
    (try
      current_module := module_name;
      (try !run_lines_ref (List.rev !lines)
       with exn ->
         current_module := saved_module;
         raise exn);
      current_module := saved_module;
      Hashtbl.replace loaded_module_paths abs_path true;
      module_load_stack :=
        (match !module_load_stack with
        | _ :: tl -> tl
        | [] -> []);
      Hashtbl.remove module_loading_paths abs_path;
      Str file
    with exn ->
      module_load_stack :=
        (match !module_load_stack with
        | _ :: tl -> tl
        | [] -> []);
      Hashtbl.remove module_loading_paths abs_path;
      raise exn)
    end);
  add "file-exists" (fun a ->
    let f = nth_str a 0 in
    Num (if f <> "" && Sys.file_exists f && not (Sys.is_directory f) then 1.0 else 0.0));
  add "dir-exists" (fun a ->
    let d = nth_str a 0 in
    Num (if d <> "" && Sys.file_exists d && Sys.is_directory d then 1.0 else 0.0));
  add "mkdir" (fun a ->
    let dir = nth_str a 0 in
    if dir = "" then failwith "mkdir: missing directory";
    (* mkdir -p equivalent that supports absolute paths *)
    let is_abs = String.length dir > 0 && dir.[0] = '/' in
    let parts =
      List.filter (fun p -> p <> "") (String.split_on_char '/' dir)
    in
    let _ =
      List.fold_left
        (fun acc p ->
          let path =
            if acc = "" then p
            else if acc = "/" then "/" ^ p
            else Filename.concat acc p
          in
          if Sys.file_exists path then begin
            if not (Sys.is_directory path) then
              failwith ("mkdir: path component is not a directory: " ^ path)
          end else
            Unix.mkdir path 0o755;
          path)
        (if is_abs then "/" else "")
        parts
    in
    Str dir);
  add "mv" (fun a ->
    let old_path = nth_str a 0 in
    let new_path = nth_str a 1 in
    if old_path = "" || new_path = "" then failwith "mv: missing arguments";
    Sys.rename old_path new_path;
    Str new_path);
  add "cp" (fun a ->
    let old_path = nth_str a 0 in
    let new_path = nth_str a 1 in
    if old_path = "" || new_path = "" then failwith "cp: missing arguments";
    let ic = open_in_bin old_path in
    let oc = open_out_bin new_path in
    let buf = Bytes.create 65536 in
    let rec copy_loop () =
      let n = input ic buf 0 (Bytes.length buf) in
      if n > 0 then begin
        output oc buf 0 n;
        copy_loop ()
      end
    in
    copy_loop ();
    close_in ic;
    close_out oc;
    let st = Unix.stat old_path in
    Unix.chmod new_path st.Unix.st_perm;
    Unix.utimes new_path st.Unix.st_atime st.Unix.st_mtime;
    Str new_path);
  add "rm" (fun a ->
    let path = nth_str a 0 in
    if path = "" then failwith "rm: missing path";
    Sys.remove path;
    Str path);
  add "cwd" (fun _ ->
    Str (Sys.getcwd ()));
  add "chdir" (fun a ->
    let dir = nth_str a 0 in
    if dir = "" then failwith "chdir: missing directory";
    Sys.chdir dir;
    Str dir);
  add "basename" (fun a ->
    let path = nth_str a 0 in
    if path = "" then failwith "basename: missing path";
    Str (Filename.basename path));
  add "dirname" (fun a ->
    let path = nth_str a 0 in
    if path = "" then failwith "dirname: missing path";
    Str (Filename.dirname path));
  add "path-type" (fun a ->
    let path = nth_str a 0 in
    if path = "" then failwith "path-type: missing path";
    Str (path_type path));
  add "path-is-file" (fun a ->
    let path = nth_str a 0 in
    if path = "" then failwith "path-is-file: missing path";
    Num (if path_type path = "file" then 1.0 else 0.0));
  add "path-is-dir" (fun a ->
    let path = nth_str a 0 in
    if path = "" then failwith "path-is-dir: missing path";
    Num (if path_type path = "dir" then 1.0 else 0.0));
  add "path-is-socket" (fun a ->
    let path = nth_str a 0 in
    if path = "" then failwith "path-is-socket: missing path";
    Num (if path_type path = "socket" then 1.0 else 0.0));
  add "path-is-link" (fun a ->
    let path = nth_str a 0 in
    if path = "" then failwith "path-is-link: missing path";
    Num (if path_type path = "link" then 1.0 else 0.0));
  add "path-join" (fun a ->
    let parts = List.map to_str a in
    match parts with
    | [] -> failwith "path-join: expected at least one segment"
    | p :: rest ->
      Str (List.fold_left Filename.concat p rest));
  add "date" (fun _ ->
    Str (format_date_ymd (Unix.localtime (Unix.time ()))));
  add "time" (fun _ ->
    Num (float_of_int (int_of_float (Unix.time ()))));
  add "time-iso" (fun _ ->
    Str (format_time_iso (Unix.gmtime (Unix.time ()))));
  add_sys "sys.capabilities" (fun _ ->
    let items =
      Hashtbl.fold (fun name _ acc -> Str name :: acc) sys_capabilities []
      |> List.sort (fun a b -> compare (to_str a) (to_str b))
    in
    sys_ok [("items", Arr (dynarr_of_list items))]);
  add_sys "posix.getpid" (fun args ->
    if args <> [] then sys_err 22 "posix.getpid: expected no arguments" []
    else sys_ok [("pid", Num (float_of_int (Unix.getpid ())))]);
  add_sys "posix.getppid" (fun args ->
    if args <> [] then sys_err 22 "posix.getppid: expected no arguments" []
    else sys_ok [("pid", Num (float_of_int (Unix.getppid ())))]);
  add_sys "posix.stat" (fun args ->
    match Option.bind (list_nth_opt args 0) sys_path_arg with
    | None -> sys_err 22 "posix.stat: missing path" []
    | Some path ->
      (try
         let st = Unix.stat path in
         sys_ok (("path", Str path) :: ("exists", Num 1.0) :: stats_fields st)
       with Unix.Unix_error (err, _, _) ->
         sys_err (errno_code err) ("posix.stat: " ^ Unix.error_message err)
           [("path", Str path); ("exists", Num 0.0); ("type", Str "missing")]));
  add_sys "posix.lstat" (fun args ->
    match Option.bind (list_nth_opt args 0) sys_path_arg with
    | None -> sys_err 22 "posix.lstat: missing path" []
    | Some path ->
      (try
         let st = Unix.lstat path in
         sys_ok (("path", Str path) :: ("exists", Num 1.0) :: stats_fields st)
       with Unix.Unix_error (err, _, _) ->
         sys_err (errno_code err) ("posix.lstat: " ^ Unix.error_message err)
           [("path", Str path); ("exists", Num 0.0); ("type", Str "missing")]));
  add_sys "posix.access" (fun args ->
    match Option.bind (list_nth_opt args 0) sys_path_arg with
    | None -> sys_err 22 "posix.access: missing path" []
    | Some path ->
      let mode =
        match list_nth_opt args 1 with
        | None -> "e"
        | Some v ->
          let s = to_str v in
          if s = "" then "e" else s
      in
      let valid_mode =
        let len = String.length mode in
        len > 0 &&
        let rec loop i =
          if i >= len then true
          else
            match mode.[i] with
            | 'e' | 'r' | 'w' | 'x' -> loop (i + 1)
            | _ -> false
        in
        loop 0
      in
      if not valid_mode then
        sys_err 22 "posix.access: mode must only contain e/r/w/x" []
      else
        let check flag =
          try
            match flag with
            | 'e' -> Sys.file_exists path
            | 'r' -> Unix.access path [Unix.R_OK]; true
            | 'w' -> Unix.access path [Unix.W_OK]; true
            | 'x' -> Unix.access path [Unix.X_OK]; true
            | _ -> false
          with Unix.Unix_error _ -> false
        in
        let allowed =
          let rec loop i =
            if i >= String.length mode then true
            else if check mode.[i] then loop (i + 1)
            else false
          in
          loop 0
        in
        sys_ok [("path", Str path); ("mode", Str mode); ("allowed", Num (if allowed then 1.0 else 0.0))]);
  add_sys "posix.readlink" (fun args ->
    match Option.bind (list_nth_opt args 0) sys_path_arg with
    | None -> sys_err 22 "posix.readlink: missing path" []
    | Some path ->
      (try
         let target = Unix.readlink path in
         sys_ok [("path", Str path); ("target", Str target)]
       with Unix.Unix_error (err, _, _) ->
         sys_err (errno_code err) ("posix.readlink: " ^ Unix.error_message err)
           [("path", Str path)]));
  add_sys "posix.symlink" (fun args ->
    let target =
      match list_nth_opt args 0 with
      | Some (Str s) when s <> "" -> Some s
      | Some v ->
        let s = to_str v in
        if s = "" || s = "<array>" || s = "<dict>" || s = "<regex>" then None else Some s
      | None -> None
    in
    let path = Option.bind (list_nth_opt args 1) sys_path_arg in
    (match target, path with
    | None, _ -> sys_err 22 "posix.symlink: missing target" []
    | _, None -> sys_err 22 "posix.symlink: missing path" []
    | Some target, Some path ->
      (try
         Unix.symlink target path;
         sys_ok [("path", Str path); ("target", Str target)]
       with Unix.Unix_error (err, _, _) ->
         sys_err (errno_code err) ("posix.symlink: " ^ Unix.error_message err)
           [("path", Str path)])));
  add_sys "posix.unlink" (fun args ->
    match Option.bind (list_nth_opt args 0) sys_path_arg with
    | None -> sys_err 22 "posix.unlink: missing path" []
    | Some path ->
      (try
         Unix.unlink path;
         sys_ok [("path", Str path); ("removed", Num 1.0)]
       with Unix.Unix_error (err, _, _) ->
         sys_err (errno_code err) ("posix.unlink: " ^ Unix.error_message err)
           [("path", Str path); ("removed", Num 0.0)]));
  add_sys "posix.mkdir" (fun args ->
    let path = Option.bind (list_nth_opt args 0) sys_path_arg in
    let mode =
      match list_nth_opt args 1 with
      | None -> Some 0o777
      | Some v -> parse_mode_value v
    in
    (match path, mode with
    | None, _ -> sys_err 22 "posix.mkdir: missing path" []
    | _, None -> sys_err 22 "posix.mkdir: mode must be numeric or octal string" []
    | Some path, Some mode ->
      (try
         Unix.mkdir path mode;
         sys_ok
           [("path", Str path); ("mode", Num (float_of_int mode));
            ("mode-oct", Str (Printf.sprintf "%04o" (mode land 0o7777)))]
       with Unix.Unix_error (err, _, _) ->
         sys_err (errno_code err) ("posix.mkdir: " ^ Unix.error_message err)
           [("path", Str path)])));
  add_sys "posix.rmdir" (fun args ->
    match Option.bind (list_nth_opt args 0) sys_path_arg with
    | None -> sys_err 22 "posix.rmdir: missing path" []
    | Some path ->
      (try
         Unix.rmdir path;
         sys_ok [("path", Str path); ("removed", Num 1.0)]
       with Unix.Unix_error (err, _, _) ->
         sys_err (errno_code err) ("posix.rmdir: " ^ Unix.error_message err)
           [("path", Str path); ("removed", Num 0.0)]));
  add_sys "posix.chmod" (fun args ->
    let path = Option.bind (list_nth_opt args 0) sys_path_arg in
    let mode = Option.bind (list_nth_opt args 1) parse_mode_value in
    (match path, mode with
    | None, _ -> sys_err 22 "posix.chmod: missing path" []
    | _, None -> sys_err 22 "posix.chmod: mode must be numeric or octal string" []
    | Some path, Some mode ->
      (try
         Unix.chmod path mode;
         sys_ok
           [("path", Str path); ("mode", Num (float_of_int mode));
            ("mode-oct", Str (Printf.sprintf "%04o" (mode land 0o7777)))]
       with Unix.Unix_error (err, _, _) ->
         sys_err (errno_code err) ("posix.chmod: " ^ Unix.error_message err)
           [("path", Str path)])));
  add_sys "posix.utime" (fun args ->
    let path = Option.bind (list_nth_opt args 0) sys_path_arg in
    let atime = list_nth_opt args 1 in
    let mtime = list_nth_opt args 2 in
    let parse_num = function
      | Some (Num f) when classify_float f <> FP_nan && classify_float f <> FP_infinite -> Some f
      | Some (Str s) when re_matches re_timeout_seconds s -> Some (float_of_string s)
      | _ -> None
    in
    (match path, parse_num atime, parse_num mtime with
    | None, _, _ -> sys_err 22 "posix.utime: missing path" []
    | _, None, _ -> sys_err 22 "posix.utime: atime must be numeric" []
    | _, _, None -> sys_err 22 "posix.utime: mtime must be numeric" []
    | Some path, Some atime, Some mtime ->
      (try
         Unix.utimes path atime mtime;
         sys_ok [("path", Str path); ("atime", Num atime); ("mtime", Num mtime)]
       with Unix.Unix_error (err, _, _) ->
         sys_err (errno_code err) ("posix.utime: " ^ Unix.error_message err)
           [("path", Str path)])));
  add_sys "posix.realpath" (fun args ->
    match Option.bind (list_nth_opt args 0) sys_path_arg with
    | None -> sys_err 22 "posix.realpath: missing path" []
    | Some path ->
      (try
         let resolved = Unix.realpath path in
         sys_ok [("path", Str path); ("realpath", Str resolved)]
       with Unix.Unix_error (err, _, _) ->
         sys_err (errno_code err) ("posix.realpath: " ^ Unix.error_message err)
           [("path", Str path)]));
  add "sys" (fun a ->
    let capability = nth_str a 0 in
    if capability = "" then failwith "sys: missing capability";
    if capability = "<array>" || capability = "<dict>" || capability = "<regex>" then
      failwith "sys: capability must be a string";
    let args =
      match a with
      | [] -> []
      | _ :: tl -> tl
    in
    match hashtbl_find_opt sys_capabilities capability with
    | None -> sys_err 38 ("sys: unknown capability '" ^ capability ^ "'") []
    | Some handler ->
      (try handler args
       with exn ->
         let msg =
           match exn with
           | Failure m -> m
           | Sys_error m -> m
           | _ -> Printexc.to_string exn
         in
         let msg =
           if String.length msg > 0 && msg.[String.length msg - 1] = '\n' then
             String.sub msg 0 (String.length msg - 1)
           else
             msg
         in
         sys_err 255 ("sys/" ^ capability ^ ": " ^ msg) []));

  (* Misc *)
  add "user-input" (fun a ->
    let prompt = nth_str a 0 in
    if prompt <> "" then (print_string prompt; flush stdout);
    let line = try input_line stdin with End_of_file -> "" in
    Str line);
  add "die" (fun a ->
    let msg = nth_str a 0 in
    failwith (if msg = "" then "died" else msg));
  add "stderr" (fun a ->
    let out = String.concat "" (List.map to_str a) in
    Printf.eprintf "%s\n" out;
    Str out);
  add "run" (fun a ->
    let timeout_s = parse_timeout_seconds (list_nth_opt a 1) "run" in
    run_command_capture (nth_val a 0) timeout_s);
  add "pipe" (fun a ->
    let timeout_s = parse_timeout_seconds (list_nth_opt a 1) "pipe" in
    let cmds_val = nth_val a 0 in
    let commands =
      match cmds_val with
      | Arr r ->
        List.map (normalize_command_argv "pipe") (dynarr_to_list r)
      | _ ->
        failwith "pipe: command list must be an array"
    in
    run_pipeline_capture commands timeout_s);
  add "sh" (fun a ->
    let cmd = nth_str a 0 in
    let allow_unsafe = is_truthy (nth_val a 1) in
    if cmd = "" then failwith "sh: missing command";
    if (not allow_unsafe) && has_unsafe_shell_metacharacters cmd then
      failwith "sh: unsafe shell metacharacters detected; use run()/pipe() or pass 1 as second arg to override";
    let ic = Unix.open_process_in cmd in
    let buf = Buffer.create 256 in
    (try while true do Buffer.add_char buf (input_char ic) done
     with End_of_file -> ());
    let status = Unix.close_process_in ic in
    (match status with
    | Unix.WEXITED 0 -> ()
    | Unix.WEXITED n ->
      failwith (Printf.sprintf "sh: '%s' exited with status %d" cmd n)
    | Unix.WSIGNALED n ->
      failwith (Printf.sprintf "sh: '%s' terminated by signal %d" cmd n)
    | Unix.WSTOPPED n ->
      failwith (Printf.sprintf "sh: '%s' stopped by signal %d" cmd n));
    (* chomp trailing newline *)
    let s = Buffer.contents buf in
    let s = if String.length s > 0 && s.[String.length s - 1] = '\n'
            then String.sub s 0 (String.length s - 1) else s in
    Str s);

  (* Process *)
  add "sleep" (fun a ->
    let s = nth_num a 0 in
    let s = if s < 0.0 then 0.0 else s in
    Unix.sleepf s;
    Num 0.0);
  add "kill" (fun a ->
    let signal = int_of_float (nth_num a 0) in
    let pid = int_of_float (nth_num a 1) in
    Unix.kill pid signal;
    Num 0.0);
  add "wait" (fun a ->
    let pid = int_of_float (nth_num a 0) in
    let pid = if pid = 0 then -1 else pid in
    let (res_pid, status) = Unix.waitpid [] pid in
    let code = status_to_code status in
    let sig_n = match status with Unix.WSIGNALED n -> n | _ -> 0 in
    let h = Hashtbl.create 4 in
    Hashtbl.replace h "pid" (Num (float_of_int res_pid));
    Hashtbl.replace h "status" (Num (float_of_int code));
    Hashtbl.replace h "code" (Num (float_of_int code));
    Hashtbl.replace h "signal" (Num (float_of_int sig_n));
    Dict h);
  add "times" (fun _ ->
    let t = Unix.times () in
    Arr (dynarr_of_list [
      Num t.Unix.tms_utime; Num t.Unix.tms_stime;
      Num t.Unix.tms_cutime; Num t.Unix.tms_cstime]));
  add "umask" (fun a ->
    let v = nth_val a 0 in
    match v with
    | Nil ->
      let prev = Unix.umask 0 in
      ignore (Unix.umask prev);
      Num (float_of_int prev)
    | _ ->
      let mode = int_of_float (to_num v) in
      Num (float_of_int (Unix.umask mode)));

  let alias new_name old_name =
    Hashtbl.replace builtins new_name (Hashtbl.find builtins old_name)
  in
  alias "text->len" "length";
  alias "text->upper" "upper";
  alias "text->lower" "lower";
  alias "text->replace" "replace";
  alias "text->replace-all" "replace-all";
  alias "grep" "filter";

  alias "array->len" "len";
  alias "array->get" "get";
  alias "array->push" "push";
  alias "array->pop" "pop";

  alias "dict->get" "dict-get";
  alias "dict->set" "dict-set";
  alias "dict->keys" "dict-keys";
  alias "dict->has" "dict-has";
  alias "dict->del" "dict-del";

  alias "dir->exists" "dir-exists";
  alias "dir->entries" "read-dir";
  alias "dir->list" "read-dir";
  alias "file->exists" "file-exists";
  alias "dir->cwd" "cwd";
  alias "dir->chdir" "chdir";
  alias "path->join" "path-join";
  alias "path->basename" "basename";
  alias "path->dirname" "dirname";
  alias "path->type" "path-type";
  alias "path->is-file" "path-is-file";
  alias "path->is-dir" "path-is-dir";
  alias "path->is-socket" "path-is-socket";
  alias "path->is-link" "path-is-link";

  alias "file->text" "read-file";
  alias "text->file" "write-file";
  alias "file->append" "append-file";
  alias "file->lines" "read-file-lines";
  alias "lines->file" "write-lines-file";
  alias "file->remove" "rm";
  alias "sys->call" "sys";
  alias "date->today" "date";
  alias "time->now" "time";
  alias "time->iso-utc" "time-iso";
  alias "pwd" "cwd";
  alias "cd" "chdir";
  alias "read" "user-input"

(* ============================================================
   Main
   ============================================================ *)

let () =
  register_builtins ();
  run_lines_ref := run_program;
  run_nodes_ref := run_nodes;
  let argv = ref (Array.to_list Sys.argv |> List.tl) in
  let check_mode = ref false in
  let rec consume_options () =
    match !argv with
    | opt :: rest when String.length opt > 0 && opt.[0] = '-' ->
      if opt = "--check" then begin
        check_mode := true;
        argv := rest;
        consume_options ()
      end else if opt = "--strict-globals" then begin
        strict_globals_mode := true;
        argv := rest;
        consume_options ()
      end else
        failwith ("Unknown option: " ^ opt)
    | _ -> ()
  in
  consume_options ();
  if !check_mode then begin
    match !argv with
    | file :: _ ->
      if run_static_check file then exit 0 else exit 1
    | [] ->
      failwith "Usage: shelm --check <file>"
  end;
  (match !argv with
  | file :: _ when !strict_globals_mode ->
    if not (run_static_check file) then exit 1
  | _ -> ());

  let lines =
    match !argv with
    | file :: rest ->
      let ic = open_in file in
      let lines = ref [] in
      (try while true do lines := input_line ic :: !lines done
       with End_of_file -> ());
      close_in ic;
      Hashtbl.replace module_dirs main_module (Filename.dirname file);
      predeclare_global_if_missing "PATH";
      Hashtbl.replace globals "PATH" (Str file);
      let args =
        List.mapi (fun idx arg ->
          let n = idx + 1 in
          let g = Printf.sprintf "ARG%d" n in
          predeclare_global_if_missing g;
          Hashtbl.replace globals g (Str arg);
          Str arg
        ) rest
      in
      predeclare_global_if_missing "ARGS";
      Hashtbl.replace global_arrays "ARGS" (Arr (dynarr_of_list args));
      List.rev !lines
    | [] ->
      let lines = ref [] in
      (try while true do lines := input_line stdin :: !lines done
       with End_of_file -> ());
      predeclare_global_if_missing "ARGS";
      Hashtbl.replace global_arrays "ARGS" (Arr (dynarr_empty ()));
      List.rev !lines
  in
  let env_dict = Hashtbl.create 64 in
  Array.iter (fun entry ->
    match string_index_opt entry '=' with
    | Some idx ->
      let k = String.sub entry 0 idx in
      let v = String.sub entry (idx + 1) (String.length entry - idx - 1) in
      Hashtbl.replace env_dict k (Str v)
    | None -> ()
  ) (Unix.environment ());
  predeclare_global_if_missing "ENV";
  Hashtbl.replace global_dicts "ENV" (Dict env_dict);
  run_program lines;
  if !strict_globals_mode then
    validate_required_globals_runtime ()
