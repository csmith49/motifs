type pattern_graph = (Filter.t, Kinder.t) Core.Structure.t

type t = {
    selector : Core.Identifier.t;
    structure : pattern_graph;
}

val equal : t -> t -> bool

val to_json : t -> Yojson.Basic.t
val of_json : Yojson.Basic.t -> t option