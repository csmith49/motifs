type t

type enumeration = ?filter:(Delta.t -> bool) -> ?verbose:(bool) -> t -> Matcher.Motif.t list

val from_independent_examples : Domain.SQL.db -> Domain.View.t -> Core.Identifier.t list -> int -> t

val enumerate : enumeration