open Graph
open Core

module DocGraph = SemanticGraph.Make(Identifier)(Value.Map)(Value)

type t = DocGraph.t

module DocJSON = Representation.JSONRepresentation(DocGraph)

(* loading from file *)
let from_file : string -> t = fun filename -> filename
    |> Yojson.Basic.from_file
    |> DocJSON.of_json
    |> CCOpt.get_exn

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