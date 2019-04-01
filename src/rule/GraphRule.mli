type t

(* given a rule and a document, find all identifier vectors matching rule in doc *)
val apply : t -> Document.t -> (Identifier.t list) list

(* list of vertices in rule *)
val vertices : t -> Identifier.t list

(* for construction *)
val singleton : Identifier.t -> t

val add_vertex : t -> Identifier.t -> t

val add_predicate : t -> Identifier.t -> Predicate.t -> t

val add_edge : t -> Identifier.t -> Identifier.t -> t

val add_filtered_edge : t -> Identifier.t -> Filter.t -> Identifier.t -> t