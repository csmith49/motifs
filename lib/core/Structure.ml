module Graph = Utility.Graph.Make(Identifier)

include Graph

let of_json j2v j2e json =
    let j2edge json =
        let src = Utility.JSON.get "source" Identifier.of_json json in
        let lbl = Utility.JSON.get "label" j2e json in
        let dest = Utility.JSON.get "destination" Identifier.of_json json in
        match src, lbl, dest with
            | Some src, Some lbl, Some dest -> Some (src, lbl, dest)
            | _ -> None in
    let j2vertex json =
        let id = Utility.JSON.get "identifier" Identifier.of_json json in
        let lbl = Utility.JSON.get "label" j2v json in
        match id, lbl with
            | Some id, Some lbl -> Some (id, lbl)
            | _ -> None in
    let vertices = json
        |> Utility.JSON.get "vertices" (Utility.JSON.list j2vertex) in
    let edges = json
        |> Utility.JSON.get "edges" (Utility.JSON.list j2edge) in
    match vertices, edges with
        | Some vertices, Some edges -> empty
            |> CCList.fold_right (fun (v, l) -> add_vertex v l) vertices
            |> CCList.fold_right add_edge edges
            |> CCOpt.return
        | _ -> None

let to_json (v2j : 'v -> Yojson.Basic.t) (e2j : 'e -> Yojson.Basic.t) (g : ('v, 'e) t) : Yojson.Basic.t =
    let vertices = g
        |> vertices
        |> CCList.filter_map (fun v -> match label v g with
            | Some lbl -> `Assoc [
                ("identifier", Identifier.to_json v);
                ("label", v2j lbl)
            ] |> CCOpt.return
            | None -> None) in
    let edges = g
        |> edges
        |> CCList.map (fun (src, lbl, dest) -> `Assoc [
            ("source", Identifier.to_json src);
            ("label", e2j lbl);
            ("destination", Identifier.to_json dest)
        ]) in
    `Assoc [
        ("edges", `List edges);
        ("vertices", `List vertices)
    ]

let lift_equal eq left right = match left, right with
    | (src, lbl, dest), (src', lbl', dest') ->
        (Identifier.equal src src') &&
        (Identifier.equal dest dest') &&
        (eq lbl lbl')
let lift_compare cmp left right = match left, right with
    | (src, lbl, dest), (src', lbl', dest') ->
        let src_cmp = Identifier.compare src src' in
        if src_cmp = 0 then
            let lbl_cmp = cmp lbl lbl' in
            if lbl_cmp = 0 then
                Identifier.compare dest dest'
            else lbl_cmp
        else src_cmp
(* TODO
    bijection between identifiers

    start with simple bijection (target node mapped to something)

    pick any other node in the embedded graph

    find all constraints between that node and nodes already chosen

    select nodes in the large graph that satisfy those constraints

    extend bijection

    repeat until total subgraph bijection found - by construction, will satisfy constraints


 *)

module Embedding = struct
    module IdentBijection = CCBijection.Make(Identifier)(Identifier)

    type t = IdentBijection.t

    let domain embedding = embedding
        |> IdentBijection.to_list
        |> CCList.map fst
    let codomain embedding = embedding
        |> IdentBijection.to_list
        |> CCList.map snd
    
    let empty = IdentBijection.empty
    let extend left right embedding = IdentBijection.add left right embedding
    let image left embedding = 
        try Some (IdentBijection.find_left left embedding)
        with Not_found -> None
end

(* type ('v, 'u, 'e, 'g) task = {
    source : ('v, 'e) t;
    destination : ('u, 'g) t;
    vertex_map : 'v -> 'u -> bool;
    edge_map : 'e -> 'g -> bool;
}

let edges_from x y graph = outgoing x graph
    |> CCList.filter (fun (_, _, dest) -> Identifier.equal y dest)
let (->+) x y = edges_from x y

let refine : ('v, 'u, 'e, 'g) task -> Embedding.t -> Embedding.t list = fun task -> fun embedding ->
    let dom = Embedding.domain embedding in
    let target = task.source
        |> vertices
        |> CCList.filter (fun v -> CCList.mem ~eq:Identifier.equal v dom)
        |> CCList.hd in
    let in_constraints = CCList.flat_map (fun x -> task.source |> x ->+ target) dom in
    let in_solutions = CCList.flat_map (fun (src, lbl, _) -> match Embedding.image src embedding with
        | None -> []
        | Some img -> task.destination
            |> outgoing img
            |> CCList.filter_map (fun (_, lbl', dest') ->
                if task.vertex_map target dest' && task.edge_map lbl lbl' then
                    Some dest'
                else None))
        in_constraints in
    let out_constraints = CCList.flat_map (fun x -> task.source |> target ->+ x) dom in
    let out_solutions = CCList.flat_map (fun (_, lbl, dest) -> match Embedding.image dest embedding with
        | None -> []
        | Some img -> task.destination
            |> incoming img
            |> CCList.filter_map (fun (src', lbl', _) ->
                if task.vertex_map target src' && task.edge_map lbl lbl' then
                    Some src'
                else None))
        out_constraints in
    let solutions = CCList.inter ~eq:Identifier.equal in_solutions out_solutions in
    solutions |> CCList.map (fun s -> Embedding.extend target s embedding) *)
