module RuleGraph = SemanticGraph.Make(Identifier)(Predicate.Conjunction)(Filter)

type t = {
    graph : RuleGraph.t;
    selected : Identifier.t;
}

type rule = t

module Isomorphism = Morphism.Iso(RuleGraph)(Document.DocGraph)

module AppEmbedding : GraphSig.Embedding with 
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
        | Some c -> Predicate.Conjunction.to_string c
        | None -> "TOP" in
    let selected = if vertex = rule.selected then "!" else "" in
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

module Query = struct
    module IdentifierSet = CCSet.Make(Identifier)

    type t = {
        query : string;
        selected : Identifier.t;
    }
    (* the intermediate reps *)
    type partial = {
        p_query : string;
        bound : IdentifierSet.t
    }

    (* extracting fields *)
    let query q = q.query
    let selected q = q.selected

    (* selecting the query, effectively *)
    let to_string : t -> string = fun q -> q.query

    type query = string

    let query_of_edge : RuleGraph.edge -> query = fun e -> Printf.sprintf
        "SELECT source AS '%s', target AS '%s' FROM %s"
            (e |> RuleGraph.Edge.source |> Identifier.to_string)
            (e |> RuleGraph.Edge.destination |> Identifier.to_string)
            (e |> RuleGraph.Edge.label |> CCOpt.get_exn |> Filter.to_string)
    let opt_query_of_vertex : RuleGraph.t -> RuleGraph.vertex -> query option = fun g -> fun v ->
        match RuleGraph.label g v with
            (* TODO - fix this assumption *)
            | Some (hd :: _) -> Some (Printf.sprintf
                "SELECT id AS '%s' FROM %s WHERE value = %s"
                (Identifier.to_string v)
                (hd |> Predicate.attribute)
                (hd |> Predicate.value)
            )
            | _ -> None
    let query_of_rule : rule -> query = fun r ->
        let edge_queries = r.graph
            |> RuleGraph.edges
            |> CCList.map query_of_edge in
        let vertex_queries = r.graph
            |> RuleGraph.vertices
            |> CCList.filter_map (opt_query_of_vertex r.graph) in
        let wrapped_queries = edge_queries @ vertex_queries
            |> CCList.map (fun q -> "(" ^ q ^ ")") in
        Printf.sprintf "SELECT * FROM %s"
            (CCString.concat " NATURAL JOIN " wrapped_queries)

    let of_rule : rule -> t = fun rule ->
        {
            query = query_of_rule rule;
            selected = rule.selected;
        }
end