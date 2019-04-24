module JSONRepresentation (G : GraphSig.SemanticGraph) : (RepSig.JSONRepSig 
    with module Graph = G
) = struct
    open CCOpt.Infix

    module Graph = G

    (* convert vertices to and from *)
    let vertex_of_json json =
        let id = json |> JSON.assoc "identifier" >>= G.Vertex.of_json in
        match id with
            | Some id -> 
                let vlabel = json |> JSON.assoc "label" >>= G.VertexLabel.of_json in 
                Some (id, vlabel)
            | None -> None
    let vertex_to_json graph vertex =
        let v_json = G.Vertex.to_json vertex in
        let lbl_json = match G.label graph vertex with
            | Some lbl -> G.VertexLabel.to_json lbl
            | None -> `Null in
        JSON.of_assoc [
            ("identifier", v_json);
            ("label", lbl_json);
        ]
    
    (* convert edges to and from *)
    let edge_of_json json =
        let src = json |> JSON.assoc "source" >>= G.Vertex.of_json in
        let dest = json |> JSON.assoc "destination" >>= G.Vertex.of_json in
        match src, dest with
            | Some src, Some dest -> begin match json |> JSON.assoc "label" >>= G.EdgeLabel.of_json with
                | Some lbl -> Some (G.Edge.make_labeled src lbl dest)
                | None -> Some (G.Edge.make src dest)
            end
            | _ -> None
    let edge_to_json edge =
        let src_json = edge |> G.Edge.source |> G.Vertex.to_json in
        let dest_json = edge |> G.Edge.destination |> G.Vertex.to_json in
        let lbl_json = match edge |> G.Edge.label with
            | Some lbl -> G.EdgeLabel.to_json lbl
            | _ -> `Null in
        JSON.of_assoc [
            ("source", src_json);
            ("destination", dest_json);
            ("label", lbl_json);
        ]
    
    (* wholesale graph conversion *)
    let to_json graph =
        let vertex_json = graph
            |> G.vertices
            |> CCList.map (fun v -> vertex_to_json graph v) 
            |> JSON.of_list in
        let edge_json = graph
            |> G.edges
            |> CCList.map edge_to_json 
            |> JSON.of_list in
        JSON.of_assoc [
            ("vertices", vertex_json);
            ("edges", edge_json);
        ]
    let of_json json =
        let vertices = json
            |> JSON.assoc "vertices"
            |> CCOpt.map JSON.flatten_list
            >>= (fun vs -> vs |> CCList.map vertex_of_json |> CCOpt.sequence_l) in
        let edges = json
            |> JSON.assoc "edges"
            |> CCOpt.map JSON.flatten_list
            >>= (fun es -> es |> CCList.map edge_of_json |> CCOpt.sequence_l) in
        match vertices, edges with
            | Some vertices, Some edges ->
                let graph = CCList.fold_left (fun g -> fun (v, attr) -> match attr with
                    | Some attr -> G.add_labeled_vertex g v attr
                    | None -> G.add_vertex g v) G.empty vertices in
                Some (CCList.fold_left G.add_edge graph edges)
            | _ -> None
end

module DOTRepresentation (G : GraphSig.SemanticGraph) : (RepSig.DOTRepSig
    with module Graph = G
) = struct
    (* give us a handle on the graph *)
    module Graph = G

    (* simplest rep possible *)
    type dot = string

    (* utility - not exposed outside this module *)
    let edge_to_dot edge =
        let src = Graph.Edge.source edge |> Graph.Vertex.to_string in
        let dest = Graph.Edge.destination edge |> Graph.Vertex.to_string in
        match Graph.Edge.label edge with
            | Some lbl ->
                let lbl = Graph.EdgeLabel.to_string lbl in
                Printf.sprintf "%s -> %s [label=\"%s\"];" src dest lbl
            | None -> Printf.sprintf  "%s -> %s;" src dest
    let vertex_to_dot graph vertex =
        let identifier = Graph.Vertex.to_string vertex in
        match Graph.label graph vertex with
            | Some lbl -> Printf.sprintf "%s [shape=record, label=\"%s | %s\"];"
                identifier identifier (Graph.VertexLabel.to_string lbl |> CCString.escaped)
            | None -> Printf.sprintf "%s [shape=box,style=rounded];" identifier

    let graph_to_dot graph =
        let vertices = graph
            |> Graph.vertices
            |> CCList.map (vertex_to_dot graph) in
        let edges = graph
            |> Graph.edges
            |> CCList.map (edge_to_dot) in
        Printf.sprintf "digraph G {%s}" (CCString.concat "\n" (vertices @ edges))

    (* this doesn't do much, but we have it just incase we need to change the dot rep later *)
    let to_string dot = dot

    (* simple wrapper, especially because our dot rep is just a string *)
    let to_file filename dot = 
        let channel = open_out filename in
        let _ = output_string channel (to_string dot) in
        close_out channel
end