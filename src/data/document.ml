open CCOpt.Infix

module DocGraph = SemanticGraph.Make(Identifier)(Value.Map)(Value)

type t = DocGraph.t

let edge_of_json : JSON.t -> DocGraph.Edge.t option = fun json ->
    let source = json |> JSON.assoc "source" >>= Identifier.of_json in
    let dest = json |> JSON.assoc "destination" >>= Identifier.of_json in
    match source, dest with
        | Some src, Some dest -> begin match json |> JSON.assoc "label" >>= Value.of_json with
            | Some lbl -> Some (DocGraph.Edge.make_labeled src lbl dest)
            | None -> Some (DocGraph.Edge.make src dest)
        end
        | _ -> None
    
let node_of_json : JSON.t -> (Identifier.t * Value.Map.t) option = fun json ->
    let id = json |> JSON.assoc "identifier" >>= Identifier.of_json in
    let attributes = json
        |> JSON.assoc "attributes"
        >>= Value.Map.of_json
        |> CCOpt.get_or ~default:Value.Map.empty in
    match id with
        | Some id -> Some (id, attributes)
        | None -> None

let of_json : JSON.t -> t = fun json ->
    let nodes = json
        |> JSON.assoc "nodes"
        |> CCOpt.map JSON.flatten_list
        |> CCOpt.get_or ~default:[]
        |> CCList.filter_map node_of_json in
    let edges = json
        |> JSON.assoc "edges"
        |> CCOpt.map JSON.flatten_list
        |> CCOpt.get_or ~default:[]
        |> CCList.filter_map edge_of_json in
    let doc = CCList.fold_left (fun g -> fun (v, attr) -> 
            DocGraph.add_labeled_vertex g v attr
        ) DocGraph.empty nodes in
    CCList.fold_left (fun g -> fun e ->
            DocGraph.add_edge g e
        ) doc edges

(* loading from file *)
let from_file : string -> t = fun filename -> filename
    |> JSON.from_file
    |> of_json

(* accessors and manipulators and whatnot *)
let get_attributes : t -> Identifier.t -> Value.Map.t = fun doc -> fun id ->
    match DocGraph.label doc id with
        | Some attrs -> attrs
        | None -> Value.Map.empty

module DocNeighborhood = Neighborhood.Make(DocGraph)

(* given positive example, generate negative examples *)
let generate_negative : int -> Identifier.t -> t -> Identifier.t list = fun n -> fun id -> fun graph ->
    let ring = DocNeighborhood.n_ring n id graph in
        ring |> DocNeighborhood.to_list