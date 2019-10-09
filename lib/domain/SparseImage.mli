type t = (Matcher.Motif.t * Core.Identifier.t list) list

val to_json : t -> Yojson.Basic.t