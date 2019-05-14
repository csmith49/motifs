open Core

type t

val apply : t -> Value.t -> bool

val to_string : t -> string

val to_sql_action : t -> string

val compare : t -> t -> int
val equal : t -> t -> bool

module Make : sig
    val of_value : Value.t -> t
end

module Weaken : sig
    val substring : t -> t list
end

val to_json : t -> JSON.t
val of_json : JSON.t -> t option