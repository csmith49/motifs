type t = Yojson.Basic.t

exception JSONFileError of string
exception JSONConversionError

(* read from a filepath *)
val from_file : string -> t
(* write to a filepath *)
val to_file : string -> t -> unit

(* given a key, try to look up the value in `Assoc ls *)
val assoc : string -> t -> t option
(* wrap in `Assoc *)
val of_assoc : (string * t) list -> t

(* pulls out lists wrapped in `List *)
val flatten_list : t -> t list
(* wrap a list in `List *)
val of_list : t list -> t

(* pulls out strings wrapped in `String *)
val to_string_lit : t -> string option