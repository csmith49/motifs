open Core

module StringMap = CCMap.Make(CCString)

type row = Identifier.t list
type t = row StringMap.t

let row_of_json : Yojson.Basic.t -> row = function
    | `List ls -> CCList.filter_map Identifier.of_json ls
    | _ -> []

let from_file ?(keep_extension=false) : string -> t = fun filename -> 
    let json = filename |> Yojson.Basic.from_file in match json with
        | `Assoc ls ->
            CCList.fold_left (fun m -> fun (k, r) -> 
                let row = row_of_json r in
                if keep_extension then
                    StringMap.add k row m
                else let key = Filename.remove_extension k in
                    StringMap.add key row m
            ) StringMap.empty ls
        | _ -> StringMap.empty

let examples : t -> Identifier.t list = fun m ->
    StringMap.to_list m
        |> CCList.map snd
        |> CCList.flatten

let document_examples : t -> string -> Identifier.t list = fun ex -> fun k -> StringMap.find k ex