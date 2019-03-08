type t = [
    | `Int of int
    | `String of string
    | `Bool of bool
]

(* conversions from ocaml literals *)
let of_int : int -> t = fun i -> `Int i
let of_string : string -> t = fun s -> `String s
let of_bool : bool -> t = fun b -> `Bool b

(* and to ocaml literals *)
let to_int_opt : t -> int option = function
    | `Int i -> Some i
    | _ -> None
let to_string_opt : t -> string option = function
    | `String s -> Some s
    | _ -> None
let to_bool_opt : t -> bool option = function
    | `Bool b -> Some b
    | _ -> None

(* for printing *)
let to_string : t -> string = function
    | `Int i -> string_of_int i
    | `String s -> s
    | `Bool b -> string_of_bool b

(* comparisons don't really mean much with such a heterogeneous type *)
let compare = Pervasives.compare

(* converting from json representations *)
let of_json : Yojson.Basic.t -> t option = function
    | `Int i -> Some (`Int i)
    | `String s -> Some (`String s)
    | `Bool b -> Some (`Bool b)
    | _ -> None