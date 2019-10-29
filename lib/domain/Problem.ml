open Core

type filename = string
type example = (filename * Identifier.t list)

type t = {
    (* the basics *)
    files : filename list;
    examples : example list;

    (* for specifying the search *)
    views : View.t list option;
    size : int option;

    (* for limiting the search *)
    max_labels : int option;
    max_attributes : int option;
    fixed_labels : string list option;
    fixed_attributes : string list option;

    (* for re-expanding the search *)
    shortcuts : Shortcut.t list option;
}

let example_to_string example =
    let filename, ids = example in
    Printf.sprintf "{%s : [%s]}" filename (ids |> CCList.map Core.Identifier.to_string |> CCString.concat ", ")

let files p = p.files
let examples p = p.examples
let views p = p.views
let size p = p.size
let max_labels p = p.max_labels
let max_attributes p = p.max_attributes
let fixed_labels p = p.fixed_labels
let fixed_attributes p = p.fixed_attributes
let shortcuts p = p.shortcuts

let example_of_json : Yojson.Basic.t -> example option = fun json ->
    let filename = Utility.JSON.get "file" Utility.JSON.string json in
    let ids = Utility.JSON.get "example" (Utility.JSON.one_or_more Identifier.of_json) json in
    match filename, ids with
        | Some filename, Some ids -> Some (filename, ids)
        | _ -> None

let of_json : Yojson.Basic.t -> t option = fun json ->
    let files = json
        |> Utility.JSON.get "files" (Utility.JSON.list Utility.JSON.string) in
    let examples = json
        |> Utility.JSON.get "examples" (Utility.JSON.list example_of_json) in
    
    (* get and process the metadata *)
    let metadata = json
        |> Utility.JSON.get "metadata" (Utility.JSON.assoc Utility.JSON.identity)
        |> CCOpt.get_or ~default:[] in
    let size = metadata
        |> CCList.assoc_opt ~eq:CCString.equal "size"
        |> CCOpt.flat_map Utility.JSON.int in
    let max_labels = metadata
        |> CCList.assoc_opt ~eq:CCString.equal "max_labels"
        |> CCOpt.flat_map Utility.JSON.int in
    let max_attributes = metadata
        |> CCList.assoc_opt ~eq:CCString.equal "max_attributes"
        |> CCOpt.flat_map Utility.JSON.int in
    let fixed_labels = metadata
        |> CCList.assoc_opt ~eq:CCString.equal "fixed_labels"
        |> CCOpt.flat_map (Utility.JSON.list Utility.JSON.string) in
    let fixed_attributes = metadata
        |> CCList.assoc_opt ~eq:CCString.equal "fixed_attributes"
        |> CCOpt.flat_map (Utility.JSON.list Utility.JSON.string) in
    
    (* get the views *)
    let views = match CCList.assoc_opt ~eq:CCString.equal "view_db" metadata |> CCOpt.flat_map Utility.JSON.string with
        | Some filename -> metadata
            |> CCList.assoc_opt ~eq:CCString.equal "views"
            |> CCOpt.flat_map (Utility.JSON.list Utility.JSON.string)
            |> CCOpt.map (CCList.map (SQL.view filename))
        | None -> metadata
            |> CCList.assoc_opt ~eq:CCString.equal "views"
            |> CCOpt.flat_map (Utility.JSON.list Utility.JSON.string)
            |> CCOpt.map (CCList.map View.of_string) in

    (* get the shortcuts *)
    let shortcuts =
        match CCList.assoc_opt ~eq:CCString.equal "shortcuts" metadata |> CCOpt.flat_map Utility.JSON.string with
        | Some filename -> Some (Shortcut.from_file filename)
        | None -> None in
    
    match files, examples with
        | Some files, Some examples -> Some
            {
                files = files;
                examples = examples;
                views = views;
                size = size;
                max_labels = max_labels;
                max_attributes = max_attributes;
                fixed_labels = fixed_labels;
                fixed_attributes = fixed_attributes;
                shortcuts = shortcuts;
            }
        | _ -> None

let from_file : string -> t = fun filename -> Yojson.Basic.from_file filename |> of_json |> CCOpt.get_exn