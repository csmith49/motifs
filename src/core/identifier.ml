(* identifiers are integers, nothing more *)
type t = int

(* utilities for converting to and from datatypes *)
let of_json : Yojson.Basic.t -> t option = function
    | `Int i -> Some i
    | _ -> None

let to_string : t -> string = string_of_int

(* because we're just using integers, we lift comparisons and hashes appropriately *)
let compare = CCInt.compare
let hash = CCInt.hash
let equal = CCInt.equal

(* and provide a default for the graph implementations *)
let default = 0
