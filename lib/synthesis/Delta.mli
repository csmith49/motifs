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
val refine : t -> t list

(** see if a delta can be refined *)
val is_total : t -> bool