open Sig

module Make (F : Functor) : sig
    type domain
    type codomain

    val apply : domain -> codomain
end with type domain = F.Domain.t and type codomain = F.Codomain.t = struct
    type domain = F.Domain.t
    type codomain = F.Codomain.t

    let apply graph =
        let vertices = F.Domain.vertices graph in
        let edges = F.Domain.edges graph in
        let image = CCList.fold_left (fun g -> fun v ->
            let v' = F.map_vertex v in 
            match F.map_vertex_label (F.Domain.label graph v) with
                | Some label -> F.Codomain.add_labeled_vertex g v' label
                | None -> F.Codomain.add_vertex g v'
        ) F.Codomain.empty vertices in
        CCList.fold_left (fun g -> fun e ->
            let src' = F.map_vertex (F.Domain.Edge.source e) in
            let dest' = F.map_vertex (F.Domain.Edge.destination e) in
            let e' = match F.map_edge_label (F.Domain.Edge.label e) with
                | Some label -> F.Codomain.Edge.make_labeled src' label dest'
                | None -> F.Codomain.Edge.make src' dest' in
            F.Codomain.add_edge g e'
        ) image edges
end