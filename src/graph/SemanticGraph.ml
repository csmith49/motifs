module Make (V : Sig.Vertex) (VL : Sig.VertexLabel) (EL : Sig.EdgeLabel) : Sig.SemanticGraph 
    with type vertex = V.t
    and type edge_label = EL.t
    and type vertex_label = VL.t
= struct
    module Vertex = V
    module VertexLabel = VL
    module EdgeLabel = EL
    
    type vertex = Vertex.t
    type vertex_label = VertexLabel.t
    type edge_label = EdgeLabel.t

    module Edge = struct
        type label = EdgeLabel.t
        type vertex = Vertex.t
        type t = E of vertex * label option * vertex

        let make src dest = E (src, None, dest)
        let make_labeled src lbl dest = E (src, Some lbl, dest)

        let source = function E (src, _, _) -> src
        let destination = function E (_, _, dest) -> dest
        let label = function E (_, lbl, _) -> lbl
    end

    type edge = Edge.t

    type context = {
        label : vertex_label option;
        in_edges : edge list;
        out_edges : edge list;
    }

    module VertexMap = CCMap.Make(Vertex)

    type t = context VertexMap.t

    let empty = VertexMap.empty

    let mem graph vertex = VertexMap.mem vertex graph

    let in_edges graph vertex = match VertexMap.find_opt vertex graph with
        | Some context -> context.in_edges
        | None -> []
    let out_edges graph vertex = match VertexMap.find_opt vertex graph with
        | Some context -> context.out_edges
        | None -> []
    
    let label graph vertex = match VertexMap.find_opt vertex graph with
        | Some context -> context.label
        | None -> None
    
    let add_vertex graph vertex =
        let context = {label = None; in_edges = []; out_edges = []} in
        VertexMap.add vertex context graph
    let add_labeled_vertex graph vertex label =
        let context = {label = Some label; in_edges = []; out_edges = []} in
        VertexMap.add vertex context graph
    let add_label graph vertex label =
        let context = match VertexMap.find_opt vertex graph with
            | Some context -> {context with label = Some label}
            | None -> {label = Some label; in_edges = []; out_edges = []} in
        VertexMap.add vertex context graph
    let remove_label graph vertex =
        match VertexMap.find_opt vertex graph with
            | Some context -> VertexMap.add vertex {context with label = None} graph
            | _ -> graph
            
    let remove_vertex graph vertex =
        let graph = VertexMap.remove vertex graph in
        VertexMap.to_list graph
            |> CCList.map (fun (v, c) -> (v, {c with 
                in_edges = CCList.filter (fun e -> Edge.source e != vertex) c.in_edges;
                out_edges = CCList.filter (fun e -> Edge.destination e != vertex) c.out_edges;
            }))
            |> VertexMap.of_list
    
    let add_edge graph edge =
        let src_context = match VertexMap.find_opt (Edge.source edge) graph with
            | Some context ->
                {context with out_edges = edge :: context.out_edges}
            | None -> {label = None; in_edges = []; out_edges = [edge]} in
        let dest_context = match VertexMap.find_opt (Edge.destination edge) graph with
            | Some context ->
                {context with in_edges = edge :: context.in_edges}
            | None -> {label = None; in_edges = [edge]; out_edges = []} in
        graph 
            |> VertexMap.add (Edge.source edge) src_context
            |> VertexMap.add (Edge.destination edge) dest_context
    let remove_edge eq graph edge =
        let src = Edge.source edge in
        let dest = Edge.destination edge in
        let src_gone = match VertexMap.find_opt src graph with
            | Some c -> 
                VertexMap.add src {c with out_edges = CCList.filter (fun e -> not (eq edge e)) c.out_edges} graph
            | _ -> graph in
        match VertexMap.find_opt dest src_gone with
            | Some c -> 
                VertexMap.add dest {c with in_edges = CCList.filter (fun e -> not (eq edge e)) c.in_edges} src_gone
            | _ -> src_gone
    let remove_edge_label eq graph edge =
        let edge' = Edge.make (Edge.source edge) (Edge.destination edge) in
        add_edge (remove_edge eq graph edge) edge'

    let vertices graph = graph
        |> VertexMap.to_list
        |> CCList.map fst
    
    let edges graph = graph
        |> vertices
        |> CCList.flat_map (out_edges graph)

    let degree graph vertex =
        CCList.length ( (in_edges graph vertex) @ (out_edges graph vertex) )
end