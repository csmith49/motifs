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

let label_of_json : JSON.t -> label option = function
    | `String s -> Some s
    | _ -> None
let attribute_of_json : JSON.t -> attribute option = function
    | `String s -> Some s
    | _ -> None

let of_json : JSON.t -> t = fun json ->
    let labels = json
        |> JSON.assoc "labels"
        |> CCOpt.map JSON.flatten_list
        |> CCOpt.get_or ~default:[]
        |> CCList.filter_map label_of_json in
    let attributes = json
        |> JSON.assoc "attributes"
        |> CCOpt.map JSON.flatten_list
        |> CCOpt.get_or ~default:[]
        |> CCList.filter_map label_of_json in
    {
        labels = labels;
        attributes = attributes;
    }

(* loading from file *)
let from_file : string -> t = fun filename -> filename
    |> JSON.from_file
    |> of_json