(* the types *)
type label = string
type attribute = string

type t = {
    labels : label list;
    attributes : attribute list;
}

let combine : t list -> t = fun vs ->
    let labels = vs
        |> CCList.flat_map (fun v -> v.labels) 
        |> CCList.uniq ~eq:(=) in
    let attrs = vs
        |> CCList.flat_map (fun v -> v.attributes)
        |> CCList.uniq ~eq:(=) in
    {
        labels = labels;
        attributes = attrs;
    }
let labels : t -> label list = fun c -> c.labels
let attributes : t -> attribute list = fun c -> c.attributes

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