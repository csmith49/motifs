(* the types *)
type label = string
type attribute = string

type t = {
    labels : label list;
    attributes : attribute list;
}

let label_of_json : Yojson.Basic.t -> label option = function
    | `String s -> Some s
    | _ -> None
let attribute_of_json : Yojson.Basic.t -> attribute option = function
    | `String s -> Some s
    | _ -> None

let of_json : Yojson.Basic.t -> t = fun json ->
    let labels = json
        |> Document.Util.member "labels"
        |> CCOpt.map Document.Util.to_list
        |> CCOpt.get_or ~default:[]
        |> CCList.filter_map label_of_json in
    let attributes = json
        |> Document.Util.member "attributes"
        |> CCOpt.map Document.Util.to_list
        |> CCOpt.get_or ~default:[]
        |> CCList.filter_map label_of_json in
    {
        labels = labels;
        attributes = attributes;
    }

(* loading from file *)
let from_file : string -> t = fun filename -> filename
    |> Yojson.Basic.from_file
    |> of_json