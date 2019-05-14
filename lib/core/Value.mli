type t
type value = t

val of_int_lit : int -> t
val of_string_lit : string -> t
val of_bool_lit : bool -> t

val of_string : string -> t

val to_int_opt : t -> int option
val to_string_opt : t -> string option
val to_bool_opt : t -> bool option

val to_string : t -> string

val is_null : t -> bool

val compare : t -> t -> int
val equal : t -> t -> bool

val of_json : JSON.t -> t option
val to_json : t -> JSON.t

module Utility : sig
    val equality : t -> t -> bool
    val substring : t -> t -> bool
end

module Map : sig
    type t

    val empty : t
    val get : string -> t -> value option
    val add : string -> value -> t -> t
    
    val to_list : t -> (string * value) list
    
    val is_empty : t -> bool

    val keys : t -> string list
    val values : t -> value list

    val to_json : t -> JSON.t
    val of_json : JSON.t -> t option

    val to_string : t -> string
end