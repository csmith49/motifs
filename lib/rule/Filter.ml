open Core

(* filters map values into the bools - equality checking by default *)

type t = [
    | `Equality of Value.t
]

let value = function
    | `Equality v -> v

(* to avoid unpacking *)
let apply : t -> (Value.t -> bool) = function
    | `Equality tv -> fun v -> Value.equal tv v

let to_string : t -> string = function
    | `Equality v -> Value.to_string v

(* because we just store a target value, comparisons lift from value comps *)
let compare : t -> t -> int = fun l -> fun r -> match l, r with
    | `Equality l, `Equality r -> Value.compare l r
let equal : t -> t -> bool = fun l -> fun r -> match l, r with
    | `Equality l, `Equality r -> Value.equal l r

(* utilities to help construct filters *)
module Make = struct
    (* simplest wrapper possible *)
    let of_value : Value.t -> t = fun v -> `Equality v

    (* lift ocaml literals to values first *)
    let of_int : int -> t = fun i -> of_value (Value.of_int_lit i)
    let of_string : string -> t = fun s -> of_value (Value.of_string_lit s)
    let of_bool : bool -> t = fun b -> of_value (Value.of_bool_lit b)
end

(* converting to and from json *)
let to_json : t -> JSON.t = function
    | `Equality v -> `Assoc [
        ("kind", `String "equality"); 
        ("value", Value.to_json v)
    ]
let of_json : JSON.t -> t option = fun json ->
    let kind = json
        |> JSON.assoc "kind"
        |> CCOpt.flat_map JSON.to_string_lit
        |> CCOpt.get_exn in
    if kind = "equality" then json
        |> JSON.assoc "value"
        |> CCOpt.flat_map Value.of_json
        |> CCOpt.map Make.of_value
    else None
    