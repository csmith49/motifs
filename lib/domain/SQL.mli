type db

exception SQLException of string

val view : string -> string -> View.t

val of_string : string -> db

val neighborhood : db -> View.t -> Core.Identifier.t list -> int -> Doc.t

val shortcut : db -> View.t -> Shortcut.t list -> Core.Identifier.t list -> Doc.t -> Doc.t

val evaluate : db -> Matcher.Motif.t -> Core.Identifier.t list

val check_consistency : db -> Core.Identifier.t list -> Core.Identifier.t list -> Matcher.Motif.t -> bool