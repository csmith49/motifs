type t

(* check ad see if a value satisfies a filter *)
val apply : t -> Core.Value.t -> bool

(* for printing *)
val to_string : t -> string

(* for embedding in a relational algebra *)
(* constructs a string restraining "value" in the appropriate fashion *)
val where_clause_body : t -> string

(* so we can sort and compare *)
val compare : t -> t -> int
val equal : t -> t -> bool

(* construction techniques *)
module Make : sig
    (* equality check on a value *)
    val of_value : Core.Value.t -> t
end

(* how do we weaken filters to generate new graph rules? *)
module Weaken : sig
    val substring : t -> t list

    val greedy : t -> t list
end

(* conversion to and from json *)
val to_json : t -> Yojson.Basic.t
val of_json : Yojson.Basic.t -> t option