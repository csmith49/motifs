type filename = string
type example = (filename * Core.Identifier.t list)

type t

val example_to_string : example -> string

val files : t -> filename list
val examples : t -> example list
val views : t -> View.t list option
val size : t -> int option
val max_labels : t -> int option
val max_attributes : t -> int option
val fixed_labels : t -> string list option
val fixed_attributes : t -> string list option
val shortcuts : t -> Shortcut.t list option

val of_json : Yojson.Basic.t -> t option

val from_file : string -> t