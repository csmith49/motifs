open Signatures

module JSONRepresentation (G : SemanticGraph) : (JSONRepresentation 
    with module Graph = G
) = struct

    module Graph = G

    let vertex_of_json json =
        let id = json
            |> Utility.JSON.get "identifier" G.Vertex.of_json in
        match id with
            | Some id ->
                Some (id, json |> Utility.JSON.get "label" G.VertexLabel.of_json)
            | None -> None
    let vertex_to_json graph vertex =
        let v = G.Vertex.to_json vertex in
        let lbl = match G.label graph vertex with
            | Some lbl -> G.VertexLabel.to_json lbl
            | None -> `Null in
        `Assoc [
            ("identifier", v);
            ("label", lbl)
        ]

    let edge_of_json json =
        let src = json
            |> Utility.JSON.get "source" G.Vertex.of_json in
        let dest = json
            |> Utility.JSON.get "destination" G.Vertex.of_json in
        match src, dest with
            | Some src, Some dest -> begin match json |> Utility.JSON.get "label" G.EdgeLabel.of_json with
                | Some lbl -> Some (G.Edge.make_labeled src lbl dest)
                | None -> Some (G.Edge.make src dest)
            end
            | _ -> None
    let edge_to_json edge =
        let src = edge |> G.Edge.source |> G.Vertex.to_json in
        let dest = edge |> G.Edge.destination |> G.Vertex.to_json in
        let lbl = match edge |> G.Edge.label with
            | Some lbl -> G.EdgeLabel.to_json lbl
            | _ -> `Null in
        `Assoc [
            ("source", src);
            ("destination", dest);
            ("label", lbl)
        ]
    
    (* wholesale graph conversion *)
    let to_json graph =
        let vertex_json =  `List (graph
            |> G.vertices
            |> CCList.map (fun v -> vertex_to_json graph v)) in
        let edge_json = `List (graph
            |> G.edges
            |> CCList.map edge_to_json) in
        `Assoc [
            ("vertices", vertex_json);
            ("edges", edge_json);
        ]
    let of_json json =
        let vertices = Utility.JSON.get "vertices" (Utility.JSON.list vertex_of_json) json in
        let edges = Utility.JSON.get "edges" (Utility.JSON.list edge_of_json) json in
        match vertices, edges with
            | Some vertices, Some edges ->
                let graph = CCList.fold_left (fun g -> fun (v, attr) -> match attr with
                    | Some attr -> G.add_labeled_vertex g v attr
                    | None -> G.add_vertex g v) G.empty vertices in
                Some (CCList.fold_left G.add_edge graph edges)
            | _ -> None
end

module DOTRepresentation (G : SemanticGraph) : (DOTRepresentation
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