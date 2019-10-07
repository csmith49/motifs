open Domain
open Rule
open Core

let doc_subgraph n vertex doc = Document.DocNeighborhood.n_hop_subgraph n vertex doc

module DocToRuleMapping : Graph.Signatures.Functor with 
    module Domain = Document.DocGraph and
    module Codomain = GraphRule.RuleGraph
= struct
    module Domain = Document.DocGraph
    module Codomain = GraphRule.RuleGraph

    let map_vertex id = id

    let map_vertex_label lbl = match lbl with
        | Some vm -> Some (Value.Map.to_list vm
            |> CCList.map (fun (key, value) -> Predicate.Clause.clause key (Filter.Make.of_value value))
            |> Predicate.of_list)
        | None -> None
        
    let map_edge_label lbl = match lbl with
        | Some value -> Some value
        | None -> None
end

module DocToRule = Graph.Functor.Make(DocToRuleMapping)

let subgraph (n : int) (vertex : Identifier.t) (doc : Document.t) : GraphRule.t = 
{
    GraphRule.graph = doc_subgraph n vertex doc |> DocToRule.apply;
    selected = vertex;
}

module VertexSimplification = struct
    type t =
        | Project of int
        | Relax
        | Drop

    let apply : t -> Identifier.t -> GraphRule.t -> GraphRule.t = fun simpl -> fun id -> fun rule ->
        match simpl with
            | Project i -> 
                let label = GraphRule.RuleGraph.label rule.GraphRule.graph id |> CCOpt.get_exn in
                let proj = Predicate.clause_by_idx label i 
                    |> CCOpt.get_exn
                    |> Predicate.singleton in
                GraphRule.map (fun g -> GraphRule.RuleGraph.add_label g id proj) rule
            | Relax -> GraphRule.map (fun g -> GraphRule.RuleGraph.remove_label g id) rule
            | Drop -> GraphRule.map (fun g -> GraphRule.RuleGraph.remove_vertex g id) rule
    
    let generate : GraphRule.t -> Identifier.t -> t list = fun rule -> fun id ->
        let conj = match GraphRule.RuleGraph.label rule.GraphRule.graph id with
            | Some lbl -> Predicate.clauses lbl
            | None -> [] in
        let preds = match conj with
            | [] -> [Relax]
            | _ ->
                let indices = CCList.range' 0 (CCList.length conj) in
                Relax :: (CCList.map (fun i -> Project i) indices) in
        if id = rule.GraphRule.selected then preds
        else Drop :: preds

    let simplify_at_vertex : GraphRule.t -> Identifier.t -> GraphRule.t list = fun rule -> fun id ->
        let simpls = generate rule id in
        CCList.map (fun s -> apply s id rule) simpls

    let simplify : GraphRule.t -> GraphRule.t list = fun rule ->
        let vertices = GraphRule.RuleGraph.vertices rule.GraphRule.graph in
        CCList.fold_left (fun acc -> fun vertex ->
            CCList.flat_map (fun g -> simplify_at_vertex g vertex) acc
        ) [rule] vertices
end

module EdgeSimplification = struct
    type t =
        | Keep
        | Relax
        | Drop
    
    let eq = Value.equal

    let apply : t -> GraphRule.RuleGraph.edge -> GraphRule.t -> GraphRule.t = fun simpl -> fun e -> fun rule ->
        match simpl with
            | Keep -> rule
            | Relax -> GraphRule.map (fun g -> GraphRule.RuleGraph.remove_edge_label eq g e) rule
            | Drop -> GraphRule.map (fun g -> GraphRule.RuleGraph.remove_edge eq g e) rule

    (* todo - make sure removing an edge doesn't make the graph disconnected *)
    (* slash is that even important? just filter by disconnects at the end *)
    let generate : GraphRule.RuleGraph.edge -> t list = fun e ->
        match GraphRule.RuleGraph.Edge.label e with
            | Some _ -> [Keep ; Drop]
            | None -> [Keep ; Drop]
    (* note - removed RELAX as an option *)

    let simplify_at_edge : GraphRule.t -> GraphRule.RuleGraph.edge -> GraphRule.t list = fun rule -> fun e ->
        let simpls = generate e in
        CCList.map (fun s -> apply s e rule) simpls

    let simplify : GraphRule.t -> GraphRule.t list = fun rule ->
        let edges = GraphRule.RuleGraph.edges rule.GraphRule.graph in
        CCList.fold_left (fun acc -> fun edge -> 
            CCList.flat_map (fun g -> simplify_at_edge g edge) acc
        ) [rule] edges
end

module SQLMake (I : Data.Signatures.SQLData) = struct
    let candidates ?(max_size=1) (db : I.t) (view : View.t) (id : Identifier.t) : GraphRule.t list =
        let document = I.context db max_size id view in
        let rule = {
            GraphRule.graph = DocToRule.apply document;
            selected = id;
        } in
        CCList.flat_map EdgeSimplification.simplify (VertexSimplification.simplify rule)

    let connected hops = GraphRule.connected ~hops:hops
    let vertex_bounded size rule = CCList.length (GraphRule.RuleGraph.vertices rule.GraphRule.graph) <= size
    let edge_bounded degree rule = (GraphRule.max_degree rule) <= degree

    let filtered_candidates ?(max_size=1) ?(vertices=4) ?(degree=2) db view id =
        candidates ~max_size:max_size db view id
            |> CCList.filter (connected max_size)
            |> CCList.filter (vertex_bounded vertices)
            |> CCList.filter (edge_bounded degree)
end