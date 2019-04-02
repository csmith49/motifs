module DocNeighborhood = Neighborhood.Make(Document.DocGraph)

let doc_subgraph n vertex doc = DocNeighborhood.n_hop_subgraph n vertex doc

module DocToRuleMapping : Sig.Functor with 
    module Domain = Document.DocGraph and
    module Codomain = GraphRule.RuleGraph
= struct
    module Domain = Document.DocGraph
    module Codomain = GraphRule.RuleGraph

    let map_vertex id = id
    let map_vertex_label lbl = match lbl with
        | Some vm -> Some (Value.Map.to_list vm
            |> CCList.map (fun (k, v) -> Predicate.mk k (Filter.Make.of_value v))
        )
        | None -> None
    let map_edge_label lbl = match lbl with
        | Some value -> Some (Filter.Make.of_value value)
        | None -> None
end

module DocToRule = Functor.Make(DocToRuleMapping)

let subgraph (n : int) (vertex : Identifier.t) (doc : Document.t) : GraphRule.t = {
    GraphRule.graph = doc_subgraph n vertex doc |> DocToRule.apply;
    selected = [vertex];
}

(* module Simplification = struct
    type node_simpl =
        | Drop
        | RemoveLabel
        | Simplify of int
    type edge_simpl =
        | Drop
        | Simplify
end *)