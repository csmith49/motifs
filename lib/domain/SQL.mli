type db

val of_string : string -> db

val neighborhood : db -> View.t -> Core.Identifier.t -> int -> Doc.t

val evaluate : db -> Matcher.Motif.t -> Core.Identifier.t list