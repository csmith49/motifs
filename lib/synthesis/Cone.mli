type t

val from_independent_examples : Domain.SQL.db -> Domain.View.t -> Core.Identifier.t list -> int -> t

val enumerate : ?filter:(Delta.t -> bool) -> t -> Matcher.Motif.t list