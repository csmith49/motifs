type t

val of_json : JSON.t -> t option
val to_json : t -> JSON.t

val of_string : string -> t option
val to_string : t -> string

val of_int : int -> t

val compare : t -> t -> int
val equal : t -> t -> bool
val hash : t -> int

val default : t

val simplify : t list -> t -> t