type db

val of_string : string -> db

val nearby_nodes :
    db -> View.t -> Core.Identifier.t -> int -> Core.Identifier.t list

val edges_between : db -> View.t -> Core.Identifier.t list -> (Core.Identifier.t * Core.Value.t * Core.Identifier.t) list

val attributes_for : db -> View.t -> Core.Identifier.t -> Core.Value.Map.t