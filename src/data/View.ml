(* the types *)
type label = string
type attribute = string

type t = {
    labels : label list;
    attributes : attribute list;
}

type combo = t list
let combine : t list -> combo = fun x -> x
let labels : combo -> label list = fun c -> c
    |> CCList.flat_map (fun v -> v.labels)
let attributes : combo -> attribute list = fun c -> c
    |> CCList.flat_map (fun v -> v.attributes)

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