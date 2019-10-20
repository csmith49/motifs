type pattern_graph = (Filter.t, Kinder.t) Core.Structure.t

type t = {
    selector : Core.Identifier.t;
    structure : pattern_graph;
}

let pg_to_json = Core.Structure.to_json Filter.to_json Kinder.to_json
let pg_of_json = Core.Structure.of_json Filter.of_json Kinder.of_json

let to_json motif = `Assoc [
    ("selector", Core.Identifier.to_json motif.selector);
    ("structure", pg_to_json motif.structure)
]
let of_json json =
    let selector = Utility.JSON.get "selector" Core.Identifier.of_json json in
    let structure = Utility.JSON.get "structure" pg_of_json json in
    match selector, structure with
        | Some selector, Some structure -> Some {
            selector = selector ; structure = structure
        }
        | _ -> None

let hash = CCHash.poly

let to_string motif = 
    let struct_s = Core.Structure.to_string
        Filter.to_string
        Kinder.to_string
        motif.structure in
    let sel_s = Core.Identifier.to_string motif.selector in
    Printf.sprintf "select %s in\n%s" sel_s struct_s

let well_connected motif =
    let reachable = Core.Structure.Algorithms.bireachable motif.structure [motif.selector] in
    let vertices = Core.Structure.vertices motif.structure in
    vertices |>
        CCList.for_all (fun v -> CCList.mem ~eq:Core.Identifier.equal v reachable)

let well_formed motif =
    CCList.mem ~eq:Core.Identifier.equal motif.selector (Core.Structure.vertices motif.structure)

(* PARTIAL ORDER *)

module PartialOrder = struct
    (* we're going to be manipulating embeddings a bunch *)
    module E = Core.Structure.Embedding

    (* picks out nearby nodes to be candidates *)
    let candidates motif ids =
        let neighborhood = Core.Structure.Algorithms.neighborhood
            motif.structure ids 1 in
        CCList.filter (fun v -> CCList.mem ~eq:Core.Identifier.equal v ids) neighborhood

    (* check if an edge embeds *)
    let edge_embeds left embedding edge = match E.edge_image edge embedding with
        | None -> false
        | Some (src, lbl, dest) -> Core.Structure.outgoing src left.structure
            (* get all edges that actually go from src to dest *)
            |> CCList.filter (fun e -> Core.Identifier.equal
                dest
                (Core.Structure.Edge.destination e))
            (* remove any that don't satisfy our desired implication ordering *)
            |> CCList.filter (fun e -> Kinder.( (Core.Structure.Edge.label e) => lbl))
            (* make sure that some edge actually exists *)
            |> CCList.is_empty
            |> CCBool.negate
    
    (* check if a vertex embeds *)
    let vertex_embeds left right embedding vertex = match E.image vertex embedding with
        | None -> false
        | Some vertex' -> 
            match Core.Structure.label vertex right.structure, Core.Structure.label vertex' left.structure with
                | Some label, Some label' -> Filter.(label' => label) 
                | _ -> false

    (* generates candidate pairs to extend the embedding : (id, id) list *)
    let candidate_pairs left right embedding =
        let dom_candidates = candidates right (E.domain embedding) in
        let codom_candidates = candidates left (E.codomain embedding) in
        CCList.cartesian_product [dom_candidates ; codom_candidates]
            |> CCList.filter_map (fun ls -> match ls with
                | right :: left :: [] -> Some (right, left)
                | _ -> None)

    (* get edges *)
    let domain_edge_constraints right embedding vertex =
        let domain = E.domain embedding in
        let in_domain v = CCList.mem ~eq:Core.Identifier.equal v domain in
        let incoming = Core.Structure.incoming vertex right.structure
            |> CCList.filter (fun e -> in_domain (Core.Structure.Edge.source e)) in
        let outgoing = Core.Structure.outgoing vertex right.structure
            |> CCList.filter (fun e -> in_domain (Core.Structure.Edge.destination e)) in
        incoming @ outgoing

    (* check if an embedding is total *)
    let is_total right embedding = candidates right (E.domain embedding)
        |> CCList.is_empty |> CCBool.negate

    (* refine an embedding *)
    let refine left right embedding = candidate_pairs left right embedding
        |> CCList.filter_map (fun (r, l) ->
            let emb = E.extend r l embedding in
            if vertex_embeds left right emb r then
                let constraints = domain_edge_constraints right emb r in
                if CCList.for_all (fun e -> edge_embeds left emb e) constraints then
                    Some emb
                else None
            else None
        )

    (* [leq l r] is true if there is an embedding of r into l such that labels respect l => r *)
    let rec leq left right =
        let initial = E.embed right.selector left.selector in
        if vertex_embeds left right initial right.selector then
            leq_aux left right [initial]
        else false
    and leq_aux left right embeddings = match embeddings with
        | [] -> false
        | embedding :: rest -> if is_total right embedding then true else
            let embeddings = (refine left right embedding) @ rest in
            leq_aux left right embeddings

    (* alternate syntax *)
    let (<=) x y = leq x y

    let join _ = []
end