type t =
    | Top
    | Conjunct of Predicate.t * t

module Lattice : sig
    val weaken : t -> t list
end

val compare : t -> t -> int
val equal : t -> t -> bool

val implies : t -> t -> bool
val (=>) : t -> t -> bool

val of_list : Predicate.t list -> t
val of_map : Core.Value.Map.t -> t

val to_json : t -> Yojson.Basic.t
val of_json : Yojson.Basic.t -> t option

val to_string : t -> string

val apply : t -> Core.Value.Map.t -> bool