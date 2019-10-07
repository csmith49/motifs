open Core

(* filters map values into the bools - equality checking by default *)

type t = [
    | `Equality of Value.t
    | `Substring of Value.t
]

(* to avoid unpacking *)
let apply : t -> (Value.t -> bool) = function
    | `Equality tv -> fun v -> Value.Utility.equality v tv
    | `Substring ss -> fun v -> Value.Utility.substring v ss

let to_string : t -> string = function
    | `Equality v -> "eq:" ^ (Value.to_string v)
    | `Substring v -> "ss:" ^ (Value.to_string v)

let to_sql_action : t -> string = function
    | `Equality v -> "value = " ^ (Value.to_string v)
    | `Substring v -> "INSTR(value, " ^ (Value.to_string v) ^ ") > 0"

(* because we just store a target value, comparisons lift from value comps *)
let compare : t -> t -> int = fun l -> fun r -> Pervasives.compare l r

let equal : t -> t -> bool = fun l -> fun r -> match l, r with
    | `Equality l, `Equality r -> Value.equal l r
    | `Substring l, `Substring r -> Value.equal l r
    | _ -> false

(* utilities to help construct filters *)
module Make = struct
    (* simplest wrapper possible *)
    let of_value : Value.t -> t = fun v -> `Equality v

end

module Weaken = struct
    let substring _ = []

    let greedy f = substring f
end

(* converting to and from json *)
let to_json = function
    | `Equality v -> `Assoc [
        ("kind", `String "equality"); 
        ("value", Value.to_json v)]
    | `Substring v -> `Assoc [
        ("kind", `String "substring");
        ("value", Value.to_json v)
    ]
let of_json = fun json ->
    let kind = Utility.JSON.get "kind" Utility.JSON.string json in
    match kind with
        | Some s when s = "equality" -> json
            |> Utility.JSON.get "value" Value.of_json
            |> CCOpt.map (fun v -> `Equality v)
        | Some s when s = "substring" -> json
            |> Utility.JSON.get "value" Value.of_json
            |> CCOpt.map (fun v -> `Substring v)
        | _ -> None