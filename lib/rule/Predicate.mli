module Clause : sig
    (* clauses apply filters over particular attributes *)
    type t
    
    (* simple construction *)
    val clause : string -> Filter.t -> t

    (* deconstructors *)
    val attribute : t -> string
    val filter : t -> Filter.t

    (* for printing *)
    val to_string : t -> string

    (* apply to a map by looking up the attribute and applying the filter *)
    val apply : t -> Core.Value.Map.t -> bool

    (* conversion to and from json *)
    val to_json : t -> Yojson.Basic.t
    val of_json : Yojson.Basic.t -> t option

    (* weakening in the implication lattice *)
    val weaken : t -> t list

    (* constructing SQL actions *)
    val from_clause : t -> string
end

(* a predicate is a conjunction of clauses *)
type t

(* get the clauses *)
val clauses : t -> Clause.t list
val clause_by_idx : t -> int -> Clause.t option

(* make from a list *)
val of_list : Clause.t list -> t
val singleton : Clause.t -> t

(* printing *)
val to_string : t -> string

(* apply to a map *)
val apply : t -> Core.Value.Map.t -> bool

(* json manipulation *)
val to_json : t -> Yojson.Basic.t
val of_json : Yojson.Basic.t -> t option