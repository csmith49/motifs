(* shortcuts are patterns we look for in the data *)
type t

(* we have nice json representations so we can load them from the file *)
val of_json : Yojson.Basic.t -> t option
val from_file : string -> t list

(* in evaluating, we arrive at concretizations *)
type concretization = (Core.Identifier.t * Core.Identifier.t) list

(* which we construct from rows, and check if they're relevant to a neighborhood *)
val concretization_of_row : t -> string CCArray.t -> concretization option
val intersects_neighborhood : concretization -> Core.Identifier.t list -> bool

(* given a concretization, we can produce concrete edges and vertices *)
val vertices : t -> concretization -> (Core.Identifier.t * Core.Value.Map.t) list
val edges : t -> concretization -> (Core.Identifier.t * Core.Value.t * Core.Identifier.t) list

(* but to evaluate, we must be able to convert to an evaluatable structure *)
val structure : t -> (Matcher.Filter.t, Matcher.Kinder.t) Core.Structure.t

(* check if we're in a view *)
val in_view : t -> View.t -> bool