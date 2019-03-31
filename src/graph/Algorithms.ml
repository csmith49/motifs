open Sig

module SubgraphMatching (E : Embedding) : sig
    val check : E.Isomorphism.t -> E.Domain.t -> E.Codomain.t -> bool
    val find : E.Domain.t -> E.Codomain.t -> E.Isomorphism.t list
end = struct
    (* check and see if the checks given by E match on the appropriate view *)
    let convolve_vertex domain codomain pattern data =
        E.check_vertex (E.Domain.label pattern domain) (E.Codomain.label data codomain)
    let convolve_edge domain_edge codomain_edge =
        E.check_edge (E.Domain.Edge.label domain_edge) (E.Codomain.Edge.label codomain_edge)

    (* morphisms don't know anything about edges - get all possible embeddings into data *)
    let embed_edge morphism edge data =
        let src = E.Domain.Edge.source edge in
        let dest = E.Domain.Edge.destination edge in
        match E.Isomorphism.image morphism src, E.Isomorphism.image morphism dest with
            | Some src, Some dest -> src
                |> E.Codomain.out_edges data
                |> CCList.filter (fun e -> E.Codomain.Edge.destination e = dest)
                |> CCList.filter (convolve_edge edge)
            | _ -> []
    
    (* checking a single local view - vertex right, out edges embeddable *)
    let check_view morphism domain pattern data =
        (* check if the vertex embeds fine - may not even be an image *)
        let vertex_ok = match E.Isomorphism.image morphism domain with
            | Some codomain -> convolve_vertex domain codomain pattern data
            | _ -> false in
        (* if it does, check that every edge has a possible embedding *)
        if vertex_ok then E.Domain.out_edges pattern domain |>
            CCList.for_all (fun e ->
                not (embed_edge morphism e data |> CCList.is_empty)
            )
        else false

    (* check if a morphism is an appropriate embedding by checking every view *)
    let check morphism pattern data = E.Domain.vertices pattern
        |> CCList.for_all (fun v -> check_view morphism v pattern data)

    (* utilities for find *)
    let bound_vertices morphism pattern = 
        let bound = E.Isomorphism.domain morphism in pattern
            |> E.Domain.vertices
            |> CCList.filter (fun v -> CCList.mem ~eq:(=) v bound)
    let unbound_vertices morphism pattern =
        let bound = E.Isomorphism.domain morphism in pattern
            |> E.Domain.vertices
            |> CCList.filter (fun v -> not (CCList.mem ~eq:(=) v bound))
    
    (* check if a morphism covers a pattern *)
    let covers morphism pattern = CCList.is_empty (unbound_vertices morphism pattern)

    (* edges from out of the image of the morphism *)
    let partial_edges morphism pattern = 
        let bound = bound_vertices morphism pattern in
        let unbound = unbound_vertices morphism pattern in E.Domain.edges pattern
            |> CCList.filter (fun e -> CCList.mem ~eq:(=) (E.Domain.Edge.source e) bound)
            |> CCList.filter (fun e -> CCList.mem ~eq:(=) (E.Domain.Edge.destination e) unbound)

    (* given a partial edge, where can we embed it? *)
    let partial_edge_embeddings morphism edge data =
        match E.Isomorphism.image morphism (E.Domain.Edge.source edge) with
            | Some src ->
                let candidates = E.Codomain.out_edges data src in
                (* remove candidates that have a bound destination *)
                let bound = E.Isomorphism.codomain morphism in
                CCList.filter (fun e -> 
                    let dest = E.Codomain.Edge.destination e in
                    not (CCList.mem ~eq:(=) dest bound)
                ) candidates
            | None -> []

    (* given a partial edge, extend the morphism as much as possible *)
    let extend_by_partial_edge morphism edge data =
        let embedded = partial_edge_embeddings morphism edge data in
        let bindings = embedded
            |> CCList.map (fun e -> (E.Domain.Edge.source edge, E.Codomain.Edge.destination e)) in
        CCList.map (fun (l, r) -> E.Isomorphism.add morphism l r) bindings 

    (* extend a morphism, if possible *)
    let extend morphism pattern data =
        let edges = partial_edges morphism pattern in
        CCList.flat_map (fun e -> extend_by_partial_edge morphism e data) edges

    (* candidate generation operates very heuristically, and only on structural information *)
    let rec structural_candidates pattern data =
        let root = E.Domain.vertices pattern |> CCList.hd in
        let initial = E.Codomain.vertices data
            |> CCList.map (fun c -> E.Isomorphism.add E.Isomorphism.empty root c) in
        structural_candidates_aux initial pattern data
    and structural_candidates_aux worklist pattern data = match worklist with
        | m :: rest -> if covers m pattern then m :: (structural_candidates_aux rest pattern data)
            else structural_candidates_aux rest pattern data @ extend m pattern data
        | [] -> []

    (* finding matches that will return "true" when checked *)
    let find pattern data =
        let candidates = structural_candidates pattern data in
        CCList.filter (fun m -> check m pattern data) candidates
end
