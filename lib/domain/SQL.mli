type db

val of_string : string -> db

val neighborhood : db -> View.t -> Core.Identifier.t list -> int -> Doc.t

val evaluate : db -> Matcher.Motif.t -> Core.Identifier.t list
val evaluate_on : db -> Matcher.Motif.t -> Core.Identifier.t list -> Core.Identifier.t list