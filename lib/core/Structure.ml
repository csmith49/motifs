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
