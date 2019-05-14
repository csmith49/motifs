open Graph
open Core

module RuleGraph = Graph.SemanticGraph.Make(Identifier)(Predicate)(Value)

type t = {
    graph : RuleGraph.t;
    selected : Identifier.t;
}

type rule = t

module DocGraph = Domain.Document.DocGraph
module Isomorphism = Morphism.Iso(RuleGraph)(DocGraph)

module AppEmbedding : (Signatures.Embedding with 
    module Domain = RuleGraph and 
    module Codomain = Domain.Document.DocGraph and
    module Isomorphism = Isomorphism
) = struct
    module Domain = RuleGraph
    module Codomain = DocGraph

    module Isomorphism = Isomorphism

    let check_vertex pred_opt attr_opt = match pred_opt with
        | Some pred -> begin match attr_opt with
            | Some attr -> Predicate.apply pred attr
            | None -> false
        end
        | None -> true

    let check_edge filt_opt lbl_opt = match filt_opt with
        | Some filt -> begin match lbl_opt with
            | Some lbl -> Value.equal filt lbl
            | None -> false
        end
        | None -> true
end

let entity rule morphism = rule.selected
    |> Isomorphism.image morphism

module Matching = Algorithms.SubgraphMatching(AppEmbedding)

let apply rule doc = Matching.find rule.graph doc
    |> CCList.filter_map (fun m -> entity rule m)

let map f rule = {
    rule with graph = f rule.graph
}
let (>>) rule f = map f rule

(* for printing *)
let vertex_to_string rule vertex = 
    let v = Identifier.to_string vertex in
    let conj = match RuleGraph.label rule.graph vertex with
        | Some c -> Predicate.to_string c
        | None -> "TOP" in
    let selected = if vertex = rule.selected then "!" else "" in
    selected ^ v ^ " - " ^ conj
let edge_to_string edge =
    let lbl = match RuleGraph.Edge.label edge with
        | Some lbl -> "+-{" ^ (Value.to_string lbl) ^ "}->"
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
    let start = rule.selected in
    let neighborhood = RuleNeighborhood.n_hop hops start rule.graph in
    (RuleNeighborhood.size neighborhood) = (CCList.length (RuleGraph.vertices rule.graph))

let max_degree : t -> int = fun rule ->
    let degrees = RuleGraph.vertices rule.graph |> CCList.map (RuleGraph.degree rule.graph) in
    CCList.fold_left max 0 degrees

(* construction *)
module Make = struct
    let singleton id = {
        graph = RuleGraph.add_vertex RuleGraph.empty id;
        selected = id;
    }

    let add_vertex id g = {
        g with graph = RuleGraph.add_vertex g.graph id;
    }

    let add_edge src lbl dest g = 
        let edge = RuleGraph.Edge.make_labeled src lbl dest in {
            g with graph = RuleGraph.add_edge g.graph edge;
        }
end

(* for representing as a json object *)
module JSONRep = Graph.Representation.JSONRepresentation(RuleGraph)

let to_json : t -> JSON.t = fun graph ->
    let structure = JSONRep.to_json graph.graph in
    match structure with
        | `Assoc gs ->
            let selected = ("selected", graph.selected |> Identifier.to_json) in
            `Assoc (selected :: gs)
        | _ -> raise JSON.JSONConversionError