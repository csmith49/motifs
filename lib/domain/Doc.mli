type t = (Core.Value.Map.t, Core.Value.t) Core.Structure.t

val of_json : Yojson.Basic.t -> t option
val to_json : t -> Yojson.Basic.t

val to_string : t -> string

val to_motif : t -> Core.Identifier.t -> Matcher.Motif.t

val small_window : t -> Core.Identifier.t list -> int -> Core.Identifier.t list