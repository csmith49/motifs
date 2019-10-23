exception ViewException

type label = string
type attribute = string

type t

val empty : t
val add_attributes : attribute list -> t -> t
val add_labels : label list -> t -> t

val combine : t list -> t

val subsample : int -> int -> t -> t

val labels : t -> label  list
val attributes : t -> attribute list

val of_json : Yojson.Basic.t -> t option
val of_string : string -> t

val from_file : string -> t