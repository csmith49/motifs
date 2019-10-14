include Utility.Graph.GRAPH with type vertex := Identifier.t

val of_json : 
    (Yojson.Basic.t -> 'v option) -> 
    (Yojson.Basic.t -> 'e option) -> 
        Yojson.Basic.t -> ('v, 'e) t option
val to_json :
    ('v -> Yojson.Basic.t) ->
    ('e -> Yojson.Basic.t) ->
        ('v, 'e) t -> Yojson.Basic.t

val lift_equal : ('e -> 'e -> bool) -> 'e edge -> 'e edge -> bool
val lift_compare : ('e -> 'e -> int) -> 'e edge -> 'e edge -> int

module Embedding : sig
    type t
    
    val domain : t -> Identifier.t list
    val codomain : t -> Identifier.t list

    val empty : t
    val extend : Identifier.t -> Identifier.t -> t -> t
    val image : Identifier.t -> t -> Identifier.t option
end