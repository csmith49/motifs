open CCOpt.Infix

(* utility functions for construction of documents *)
module Util = struct
    let member : string -> Yojson.Basic.t -> Yojson.Basic.t option = fun s -> function
        | `Assoc ls -> ls |> CCList.assoc_opt ~eq:CCString.equal s
        | _ -> None
    let to_list : Yojson.Basic.t -> Yojson.Basic.t list = function
        | `List ls -> ls
        | _ -> []
end

module DNode = Identifier

module DEdge = struct
    type t = Value.t

    (* TODO - fix these implementations for efficiency *)
    let hash : t -> int = CCHash.poly
    let compare = Pervasives.compare
    let equal = Pervasives.(=)
    let default = `Null
end

module DocGraph = Graph.Persistent.Digraph.ConcreteBidirectionalLabeled(DNode)(DEdge)

module NodeMap = CCMap.Make(DNode)

type t = {
    structure : DocGraph.t;
    attributes : Value.Map.t NodeMap.t
}

let empty : t = {
    structure = DocGraph.empty;
    attributes = NodeMap.empty;
}

let add_edge : t -> DocGraph.E.t -> t = fun doc -> fun e ->
    {doc with structure = DocGraph.add_edge_e doc.structure e}

let add_node_w_attrs : t -> (DocGraph.V.t * Value.Map.t) -> t = fun doc -> fun (v, attrs) -> {
        structure = DocGraph.add_vertex doc.structure v;
        attributes = NodeMap.add v attrs doc.attributes;
    }

(* constructing edges from json reps *)
let edge_of_json : Yojson.Basic.t -> DocGraph.E.t option = fun json ->
    let source = json |> Util.member "source" >>= Identifier.of_json in
    let label = json |> Util.member "label" >>= Value.of_json in
    let destination = json |> Util.member "destination" >>= Identifier.of_json in
    match source, label, destination with
        | Some s, Some l, Some d -> Some (DocGraph.E.create s l d)
        | _ -> None

(* pull nodes out of json rep - adds attribute sets *)
let node_of_json : Yojson.Basic.t -> (DocGraph.V.t * Value.Map.t) option = fun json ->
    let id = json |> Util.member "identifier" >>= Identifier.of_json in
    let attributes = json 
        |> Util.member "attributes" 
        >>= Value.Map.of_json
        |> CCOpt.get_or ~default:Value.Map.empty in
    CCOpt.map (fun i -> (DocGraph.V.create i, attributes)) id

(* constructing an entire graph from a json file *)
let of_json : Yojson.Basic.t -> t = fun json ->
    let edges = json
        |> Util.member "edges"
        |> CCOpt.map Util.to_list
        |> CCOpt.get_or ~default:[]
        |> CCList.filter_map edge_of_json in
    let nodes = json
        |> Util.member "nodes"
        |> CCOpt.map Util.to_list
        |> CCOpt.get_or ~default:[]
        |> CCList.filter_map node_of_json in
    let doc = CCList.fold_left add_edge empty edges in
    CCList.fold_left add_node_w_attrs doc nodes

(* loading from file *)
let from_file : string -> t = fun filename -> filename
    |> Yojson.Basic.from_file
    |> of_json

(* accessors and manipulators and whatnot *)
let get_attributes : t -> Identifier.t -> Value.Map.t = fun doc -> fun id ->
    NodeMap.get_or ~default:Value.Map.empty id doc.attributes

(* get all edges between two identifiers *)
let get_edges : t -> Identifier.t -> Identifier.t -> DocGraph.E.t list = fun doc -> fun src -> fun dest ->
    DocGraph.find_all_edges doc.structure src dest