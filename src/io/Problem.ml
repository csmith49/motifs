type filename = string
type example = (filename * Identifier.t)

let file = fst
let vertex = snd

exception IOFailure

type t = {
    files : filename list;
    examples : example list;
}

let files p = p.files
let examples p = p.examples

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
    {
        files = files;
        examples = examples;
    }

let of_file : string -> t = fun filename ->
    JSON.from_file filename |> of_json