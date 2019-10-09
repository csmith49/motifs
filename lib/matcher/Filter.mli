type t =
    | Top
    | Conjunct of Predicate.t * t

val of_list : Predicate.t list -> t
val of_map : Core.Value.Map.t -> t

val to_json : t -> Yojson.Basic.t
val of_json : Yojson.Basic.t -> t option

val apply : t -> Core.Value.Map.t -> bool