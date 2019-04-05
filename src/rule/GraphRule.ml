module RuleGraph = SemanticGraph.Make(Identifier)(Predicate.Conjunction)(Filter)

type t = {
    graph : RuleGraph.t;
    selected : Identifier.t list;
}

module Isomorphism = Morphism.Iso(RuleGraph)(Document.DocGraph)

module AppEmbedding : Sig.Embedding with 
    module Domain = RuleGraph and 
    module Codomain = Document.DocGraph and
    module Isomorphism = Isomorphism
= struct
    module Domain = RuleGraph
    module Codomain = Document.DocGraph

    module Isomorphism = Isomorphism

    let check_vertex pred_opt attr_opt = match pred_opt with
        | Some pred -> begin match attr_opt with
            | Some attr -> Predicate.Conjunction.apply pred attr
            | None -> false
        end
        | None -> true

    let check_edge filt_opt lbl_opt = match filt_opt with
        | Some filt -> begin match lbl_opt with
            | Some lbl -> Filter.apply filt lbl
            | None -> false
        end
        | None -> true
end

let entities rule morphism = rule.selected
    |> CCList.map (fun v -> Isomorphism.image morphism v)
    |> CCOpt.sequence_l

module Matching = Algorithms.SubgraphMatching(AppEmbedding)

let apply rule doc = Matching.find rule.graph doc
    |> CCList.filter_map (fun m -> entities rule m)

let map f rule = {
    rule with graph = f rule.graph
}
let (>>) rule f = map f rule

(* for printing *)
let vertex_to_string rule vertex = 
    let v = Identifier.to_string vertex in
    let conj = match RuleGraph.label rule.graph vertex with
        | Some c -> Predicate.Conjunction.to_string c
        | None -> "TOP" in
    let selected = if CCList.mem ~eq:(=) vertex rule.selected then "!" else "" in
    selected ^ v ^ " - " ^ conj
let edge_to_string edge =
    let lbl = match RuleGraph.Edge.label edge with
        | Some lbl -> "+-{" ^ (Filter.to_string lbl) ^ "}->"
        | None -> "+->" in
    let dest = RuleGraph.Edge.destination edge |> Identifier.to_string in
        lbl ^ " " ^ dest
let print : t -> unit = fun rule ->
    let vertices = RuleGraph.vertices rule.graph in
    CCList.iter (fun v -> 
        let _ = print_endline (vertex_to_string rule v) in
        CCList.iter (fun e ->
            print_endline ("    " ^ (edge_to_string e))
        ) (RuleGraph.out_edges rule.graph v)
    ) vertices

(* specialized tests *)
module RuleNeighborhood = Neighborhood.Make(RuleGraph)

let connected ?(hops=2): t -> bool = fun rule ->
    let start = CCList.hd rule.selected in
    let neighborhood = RuleNeighborhood.n_hop hops start rule.graph in
    (RuleNeighborhood.size neighborhood) = (CCList.length (RuleGraph.vertices rule.graph))

let max_degree : t -> int = fun rule ->
    let degrees = RuleGraph.vertices rule.graph |> CCList.map (RuleGraph.degree rule.graph) in
    CCList.fold_left max 0 degrees