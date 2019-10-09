type t = (Core.Value.Map.t, Core.Value.t) Core.Structure.t

val to_motif : t -> Core.Identifier.t -> Matcher.Motif.t