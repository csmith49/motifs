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

let filename_of_json : JSON.t -> filename = function
    | `String f -> f
    | _ -> raise IOFailure
let example_of_json : JSON.t -> example = fun json ->
    let filename = JSON.assoc "file" json
        |> CCOpt.get_exn
        |> filename_of_json in
    let id = JSON.assoc "example" json
        |> CCOpt.flat_map Identifier.of_json
        |> CCOpt.get_exn in
    (filename, id)


let of_json : JSON.t -> t = fun json ->
    let files = JSON.assoc "files" json
        |> CCOpt.get_exn
        |> JSON.flatten_list
        |> CCList.map filename_of_json in
    let examples = JSON.assoc "examples" json
        |> CCOpt.get_exn
        |> JSON.flatten_list
        |> CCList.map example_of_json in
    let meta = JSON.assoc "metadata" json 
        |> CCOpt.get_or ~default:(`Assoc []) in
    let views = let open CCOpt.Infix in 
        JSON.assoc "views" meta
            >|= JSON.flatten_list
            >|= CCList.filter_map JSON.to_string_lit
            >|= CCList.map View.of_string in
    {
        files = files;
        examples = examples;
        views = views;
    }

let of_file : string -> t = fun filename ->
    JSON.from_file filename |> of_json