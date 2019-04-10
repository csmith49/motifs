module RuleGraph = SemanticGraph.Make(Identifier)(Predicate.Conjunction)(Filter)

type t = {
    graph : RuleGraph.t;
    selected : Identifier.t list;
}

type rule = t

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

(* construction *)
module Make = struct
    let singleton id = {
        graph = RuleGraph.add_vertex RuleGraph.empty id;
        selected = [id];
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
        selected : Identifier.t list;
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

    (* convert an edge to a query via remapping names *)
    let of_edge : RuleGraph.edge -> partial = fun e ->
        let src = RuleGraph.Edge.source e in
        let dest = RuleGraph.Edge.destination e in
        let label = RuleGraph.Edge.label e |> CCOpt.get_exn in
        let query = Printf.sprintf
            "SELECT source AS '%s', target AS '%s' FROM %s"
            (Identifier.to_string src)
            (Identifier.to_string dest)
            (Filter.to_string label) in
        {
            p_query = query;
            bound = IdentifierSet.of_list [src ; dest];
        }
    
    let of_vertex : RuleGraph.vertex -> RuleGraph.vertex_label option -> partial = fun id -> fun attr ->
        let query = match attr with
            (* TODO - make this assumption not really an assumption *)
            | Some (hd :: _) ->
                let value = Predicate.value hd in
                let attribute = Predicate.attribute hd in
                Printf.sprintf 
                    "SELECT id AS '%s' FROM %s WHERE 'value' = '%s'"
                    (Identifier.to_string id)
                    attribute
                    value
            | _ -> Printf.sprintf "SELECT identifier AS '%s' FROM vertex" (Identifier.to_string id) in
        {
            p_query = query;
            bound = IdentifierSet.singleton id;
        }

    let merge_partial : partial -> partial -> partial = fun l -> fun r ->
        let query = Printf.sprintf
            "SELECT * FROM (%s) NATURAL JOIN (%s)"
            l.p_query
            r.p_query in
        {
            p_query = query;
            bound = IdentifierSet.union l.bound r.bound;
        }

    let of_view : RuleGraph.t -> RuleGraph.vertex -> partial = fun g -> fun id ->
        let attr = RuleGraph.label g id in
        let v_partial = of_vertex id attr in
        let edge_partials = RuleGraph.out_edges g id
            |> CCList.map of_edge in
        CCList.fold_left merge_partial v_partial edge_partials

    let of_rule : rule -> t = fun rule ->
        let partials = RuleGraph.vertices rule.graph
            |> CCList.map (of_view rule.graph) in
        let partial = match partials with
            | hd :: tl ->
                CCList.fold_left merge_partial hd tl
            | [] -> raise Exit in
        {
            query = partial.p_query;
            selected = rule.selected;
        }
end