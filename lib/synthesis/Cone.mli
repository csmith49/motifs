type t

type enumeration = ?filter:(Delta.t -> bool) -> ?verbose:(bool) -> t -> Matcher.Motif.t list

val from_document : Domain.Doc.t -> Core.Identifier.t list -> t
val simple_from_document : Domain.Doc.t -> Core.Identifier.t list -> t
val from_examples : Domain.SQL.db -> Domain.View.t -> Core.Identifier.t list -> int -> t
val from_independent_examples : Domain.SQL.db -> Domain.View.t -> Core.Identifier.t list -> int -> t

val sample : ?count:(int) -> ?verbose:(bool) -> ?max_nodes:(int) -> ?max_edges:(int) -> t -> Matcher.Motif.t list
val enumerate : enumeration