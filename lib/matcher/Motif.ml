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
    if CCString.is_empty struct_s then Printf.sprintf "select %s in Ø" sel_s else
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
        CCList.filter (fun v -> not (CCList.mem ~eq:Core.Identifier.equal v ids)) neighborhood

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
        |> CCList.is_empty

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

    (* JOINS *)

    (* computed over candidates *)
    type candidate = {
        c_selector : Core.Identifier.t;
        c_structure : pattern_graph;
        c_embeddings : E.t list;
    }

    (* extensions are lists of images *)

    (* convert to motif *)
    let to_motif candidate = {
        selector = candidate.c_selector;
        structure = candidate.c_structure;
    }

    (* consistent if this is the only way we make candidates *)
    let fresh_id candidate = candidate.c_structure
        |> Core.Structure.vertices
        |> CCList.length
        |> Core.Identifier.of_int

    (* get an initial candidate by "intersecting" all the selectors *)
    let initial_candidate motifs =
        let selector = Core.Identifier.of_int 0 in
        let label = motifs
            |> CCList.filter_map (fun m -> Core.Structure.label m.selector m.structure)
            |> Filter.Lattice.join in
        let structure = Core.Structure.empty
            |> Core.Structure.add_vertex selector label in
        let embeddings = motifs
            |> CCList.map (fun m -> E.embed selector m.selector) in
        {
            c_selector = selector;
            c_structure = structure;
            c_embeddings = embeddings;
        }

    (* for every motif in the join, find a candidate vertex in the neighborhood *)
    let candidate_extensions motifs candidate =
        let codomains = candidate.c_embeddings
            |> CCList.map E.codomain in
        CCList.map2 candidates motifs codomains
            |> CCList.cartesian_product
    
    (* given an extension, see what the label can be via joining *)
    let extension_label motifs extension =
        CCList.map2 (fun m -> fun x -> Core.Structure.label x m.structure) motifs extension
            |> CCList.all_some
            |> CCOpt.get_or ~default:[]
            |> Filter.Lattice.join

    (* effectively a join for edges - just check if all of them are equal *)
    let rec check_edges = function
        | [] -> None
        | e :: [] -> Some e
        | e :: rest -> match check_edges rest with
            | Some e' -> if Core.Structure.Edge.equal Kinder.equal e e' then Some e else None
            | None -> None

    (* given a motif edge, get the corresponding candidate edge *)
    let edge_preimage embedding (src, lbl, dest) =
        match E.preimage src embedding, E.preimage dest embedding with
            | Some src', Some dest' -> Some (src', lbl, dest')
            | _ -> None

    (* get any edges to be added to the candidate *)
    let extension_edges motifs extension candidate vertex =
        let get_edges_bt motif codom bound =
            let structure = motif.structure in
            let incoming = Core.Structure.incoming codom structure
                |> CCList.filter (fun (_, _, dest) ->  (CCList.mem ~eq:Core.Identifier.equal dest bound)) in
            let outgoing = Core.Structure.outgoing codom structure
                |> CCList.filter (fun (src, _, _) ->  (CCList.mem ~eq:Core.Identifier.equal src bound)) in
            incoming @ outgoing in
        (* get any edges between the bound nodes and the candidate in the extension *)
        let problems = CCList.map2 (fun m -> fun codom -> (m, codom)) motifs extension
            |> CCList.map2 (fun e -> fun (m, codom) -> (m, codom, e)) candidate.c_embeddings in
        let edges_per_motif = CCList.map (fun (m, codom, e) ->
                let e = E.extend vertex codom e in
                let bound = E.codomain e in
                let edges = get_edges_bt m codom bound in
                CCList.filter_map (edge_preimage e) edges
            ) problems in
        edges_per_motif
            |> CCList.cartesian_product
            |> CCList.filter_map check_edges

    (* apply an extension *)
    let apply_extension candidate vertex label edges extension =
        let structure = candidate.c_structure
            |> Core.Structure.add_vertex vertex label
            |> CCList.fold_right Core.Structure.add_edge edges in
        let embeddings = candidate.c_embeddings
            |> CCList.map2 (fun c -> fun e -> E.extend vertex c e) extension in
        {
            candidate with
                c_structure = structure;
                c_embeddings = embeddings;
        }

    (* get all further candidates *)
    let refine_candidate motifs candidate =
        let vertex = fresh_id candidate in
        let extensions = candidate_extensions motifs candidate in
        extensions |> CCList.map (fun e ->
            let label = extension_label motifs e in
            let edges = extension_edges motifs e candidate vertex in
                apply_extension candidate vertex label edges e
        )
    
    (* apply a step - if we can't refine any more, we're already maximal, so that's good *)
    let step motifs candidate = match refine_candidate motifs candidate with
        | [] -> `Maximal
        | _ as ans -> `Refinements ans

    let join motifs =
        let candidates = ref [initial_candidate motifs] in
        let answers = ref [] in
        while not (CCList.is_empty !candidates) do
            let candidate, rest = CCList.hd_tl !candidates in
            match step motifs candidate with
                | `Maximal -> begin
                    answers := candidate :: !answers;
                    candidates := rest
                end
                | `Refinements refs -> begin
                    candidates := rest @ refs;
                end
        done;
        !answers |> CCList.map to_motif

    (* equality *)
    let equal left right = leq left right && leq right left
end