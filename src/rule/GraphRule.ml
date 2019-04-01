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

(* satisfying interface *)
let vertices rule = RuleGraph.vertices rule.graph

let singleton id = {
    graph = RuleGraph.add_vertex RuleGraph.empty id;
    selected = [id];
}

let add_vertex rule id = {
    rule with graph = RuleGraph.add_vertex rule.graph id
}

let add_predicate rule id pred = {
    rule with graph = RuleGraph.add_label rule.graph id [pred]
}

let add_edge rule src dest = 
    let edge = RuleGraph.Edge.make src dest in {
        rule with graph = RuleGraph.add_edge rule.graph edge
    }

let add_filtered_edge rule src lbl dest =
    let edge = RuleGraph.Edge.make_labeled src lbl dest in {
        rule with graph = RuleGraph.add_edge rule.graph edge
    }