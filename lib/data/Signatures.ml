open Core
open Domain

module type SQLData = sig
    (* representing a view of the data *)
    type t
 
    val of_string : string -> t

    val context : t -> int -> Identifier.t -> View.t -> Document.t

    val negative_instances : t -> int -> Identifier.t -> View.t -> Identifier.t list

    val count : t -> SQLQuery.t -> int
    val apply : t -> SQLQuery.t -> Identifier.t list

    val apply_on : t -> SQLQuery.t -> Identifier.t list -> Identifier.t list

    val scene : t -> int -> Identifier.t list
end