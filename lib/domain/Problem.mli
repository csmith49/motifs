type filename = string
type example = (filename * Core.Identifier.t list)

type t

val files : t -> filename list
val examples : t -> example list
val views : t -> View.t list option

val of_json : Yojson.Basic.t -> t option

val from_file : string -> t