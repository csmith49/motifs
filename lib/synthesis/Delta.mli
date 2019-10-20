type vertex_delta = [
    | `Keep
    | `Remove
    | `Weaken of Matcher.Filter.t
]

type edge_delta = [
    | `Keep
    | `Remove
]

type t

(** concretize a delta wrt its initial motif *)
val concretize : t -> Matcher.Motif.t

(** generate an initial delta *)
val initial : Matcher.Motif.t -> t

(** refine a delta to produce more weakenings of a motif *)
val refine : ?verbose:bool -> t -> t list

val flat_refine : ?verbose:bool -> t -> t list

(** see if a delta can be refined *)
val is_total : t -> bool

(** how many choices have we made vs how many can we make *)
val coverage : t -> float

(* comparisons *)
val equal : t -> t -> bool
val leq : t -> t -> bool