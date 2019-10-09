type t = [
    | `Constant of string * Core.Value.t
]

val of_pair : (string * Core.Value.t) -> t

val apply : t -> Core.Value.Map.t -> bool

val to_json : t -> Yojson.Basic.t
val of_json : Yojson.Basic.t -> t option