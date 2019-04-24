(* simple wrapper around yojson, with utility functions for converting to/from *)

(* base type, so we don't have to write two periods every time *)
type t = Yojson.Basic.t

(* file-based io *)
let from_file : string -> t = Yojson.Basic.from_file
let to_file : string -> t -> unit = Yojson.Basic.to_file

(* utility functions *)
let assoc : string -> t -> t option = fun key -> function
    | `Assoc ls -> ls |> CCList.assoc_opt ~eq:CCString.equal key
    | _ -> None

let flatten_list : t -> t list = function
    | `List ls -> ls
    | _ -> []

(* casting to ocaml literals *)
let to_string_lit : t -> string option = function
    | `String s -> Some s
    | _ -> None