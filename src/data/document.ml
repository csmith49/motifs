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

module DocGraph = SemanticGraph.Make(Identifier)(Value.Map)(Value)

type t = DocGraph.t

let edge_of_json : Yojson.Basic.t -> DocGraph.Edge.t option = fun json ->
    let source = json |> Util.member "source" >>= Identifier.of_json in
    let dest = json |> Util.member "destination" >>= Identifier.of_json in
    match source, dest with
        | Some src, Some dest -> begin match json |> Util.member "label" >>= Value.of_json with
            | Some lbl -> Some (DocGraph.Edge.make_labeled src lbl dest)
            | None -> Some (DocGraph.Edge.make src dest)
        end
        | _ -> None
    
let node_of_json : Yojson.Basic.t -> (Identifier.t * Value.Map.t) option = fun json ->
    let id = json |> Util.member "identifier" >>= Identifier.of_json in
    let attributes = json
        |> Util.member "attributes"
        >>= Value.Map.of_json
        |> CCOpt.get_or ~default:Value.Map.empty in
    match id with
        | Some id -> Some (id, attributes)
        | None -> None

let of_json : Yojson.Basic.t -> t = fun json ->
    let nodes = json
        |> Util.member "nodes"
        |> CCOpt.map Util.to_list
        |> CCOpt.get_or ~default:[]
        |> CCList.filter_map node_of_json in
    let edges = json
        |> Util.member "edges"
        |> CCOpt.map Util.to_list
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
    |> Yojson.Basic.from_file
    |> of_json

(* accessors and manipulators and whatnot *)
let get_attributes : t -> Identifier.t -> Value.Map.t = fun doc -> fun id ->
    match DocGraph.label doc id with
        | Some attrs -> attrs
        | None -> Value.Map.empty