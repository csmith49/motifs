open Core

type filename = string
type example = (filename * Identifier.t)

let file = fst
let vertex = snd

exception IOFailure

type t = {
    files : filename list;
    examples : example list;
    views : View.t list option;
}

let files p = p.files
let examples p = p.examples
let views p = p.views

let example_of_json : Yojson.Basic.t -> example option = fun json ->
    let filename = Utility.JSON.get "file" Utility.JSON.string json in
    let id = Utility.JSON.get "example" Identifier.of_json json in
    match filename, id with
        | Some filename, Some id -> Some (filename, id)
        | _ -> None

let of_json : Yojson.Basic.t -> t = fun json ->
    let files = json
        |> Utility.JSON.get "files" (Utility.JSON.list Utility.JSON.string)
        |> CCOpt.get_exn in
    let examples = json
        |> Utility.JSON.get "examples" (Utility.JSON.list example_of_json)
        |> CCOpt.get_exn in
    let metadata = json
        |> Utility.JSON.get "metadata" (Utility.JSON.assoc Utility.JSON.identity)
        |> CCOpt.get_or ~default:[] in
    let views = metadata
        |> CCList.assoc_opt ~eq:CCString.equal "views"
        |> CCOpt.flat_map (Utility.JSON.list Utility.JSON.string)
        |> CCOpt.map (CCList.map View.of_string) in
    {
        files = files;
        examples = examples;
        views = views;
    }

let of_file : string -> t = fun filename -> Yojson.Basic.from_file filename |> of_json