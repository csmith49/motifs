type t = Identifier.t list

let of_json : Yojson.Basic.t -> t = function
    | `List ls -> CCList.filter_map Identifier.of_json ls
    | _ -> []

let from_file : string -> string -> t = fun filename -> fun key -> filename
    |> Yojson.Basic.from_file
    |> Yojson.Basic.Util.member key
    |> of_json