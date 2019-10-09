type t =
    | Star
    | Constant of Core.Value.t

val of_value : Core.Value.t -> t
val apply : t -> Core.Value.t -> bool

val to_json : t -> Yojson.Basic.t
val of_json : Yojson.Basic.t -> t option