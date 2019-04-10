(* breaking out types for convenience *)
type t = Sqlite3.db
type row = Sqlite3.row
type headers = Sqlite3.headers

(* for messing with rows *)
module Utility = struct
    let get_indices ids header =
        ids |> CCList.map Identifier.to_string
            |> CCList.map (fun id -> CCArray.find_idx (fun h -> h = id) header)
            |> CCList.map (CCOpt.map fst)
    let extract indices row =
        indices |> CCList.map (fun idx -> match idx with
                    | Some idx -> begin match CCArray.get_safe row idx with
                        | Some opt -> opt
                        | None -> None
                        end
                    | None -> None)
    let to_identifiers extracted = extracted |> CCList.map (CCOpt.flat_map Identifier.of_string)
end

let of_filename : string -> t = fun filename ->
    Sqlite3.db_open filename

let apply_query : t -> GraphRule.Query.t -> Identifier.t list list = fun db -> fun q ->
    let query = GraphRule.Query.query q in
    let output = ref [] in
    let callback row header =
        let indices = Utility.get_indices (GraphRule.Query.selected q) header in
        let result = row |> Utility.extract indices |> Utility.to_identifiers in
            output := result :: !output in
    let _ = Sqlite3.exec db ~cb:callback query in
        !output |> CCList.filter_map CCOpt.sequence_l
