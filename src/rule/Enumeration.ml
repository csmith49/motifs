(* for enumerating graphs *)

(* stopping point - how big is a graph? we'll count nodes for now *)
let size : GraphRule.t -> int = fun gr -> GraphRule.vertices gr |> CCList.length

(* given a bunch of values, make filters *)
let mk_filters : Value.t list -> Filter.t list = fun vals ->
    vals |> CCList.map Filter.Make.of_value

(* given a bunch of keys and values, make predicates *)
let mk_preds : string list -> Value.t list -> Predicate.t list = fun keys -> fun vals ->
    let filters = mk_filters vals in
        keys |> CCList.flat_map (fun k -> CCList.map (Predicate.mk k) filters)
