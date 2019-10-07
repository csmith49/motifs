exception ViewException

type label = string
type attribute = string

type t

val combine : t list -> t

val labels : t -> label  list
val attributes : t -> attribute list

val of_json : Yojson.Basic.t -> t option

val from_file : string -> t

val of_string : string -> t