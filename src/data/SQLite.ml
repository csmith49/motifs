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

let get_attributes : t -> Identifier.t -> View.attribute list -> Value.Map.t = fun db -> fun id -> fun attrs ->
    let check attr =
        let output = ref None in
        let query = Printf.sprintf
            "SELECT value FROM %s WHERE id = '%s'"
            attr
            (Identifier.to_string id) in
        let callback row =
            let result = CCArray.get_safe row 0 in
            output := CCOpt.flatten result in
        let _ = Sqlite3.exec_no_headers db ~cb:callback query in
        !output in
    CCList.fold_left (fun m -> fun a -> match check a with
        | Some s -> Value.Map.add a (Value.of_string s) m
        | None -> m) Value.Map.empty attrs

let get_edge_labels : t -> Identifier.t -> Identifier.t -> View.combo -> View.label list =
    fun db -> fun src -> fun dest -> fun view ->
        let lbls = View.labels view in
        let check lbl =
            let output = ref false in
            let query = Printf.sprintf
                "SELECT * FROM %s WHERE source = '%s' AND target = '%s'"
                lbl
                (Identifier.to_string src)
                (Identifier.to_string dest) in
            let callback row = output := true in
            let _ = Sqlite3.exec_no_headers db ~cb:callback query in
            if !output then Some lbl else None in
        CCList.filter_map check lbls

module IdentifierSet = CCSet.Make(Identifier)

let get_adjacent_by_label : t -> IdentifierSet.t -> View.label -> IdentifierSet.t = fun db -> fun ids -> fun lbl ->
    let in_clause = ids
        |> IdentifierSet.to_list
        |> CCList.map (fun id -> Printf.sprintf "'%s'" (Identifier.to_string id))
        |> CCString.concat ", " in
    let query = Printf.sprintf
        "SELECT source AS 'identifier' FROM %s WHERE target IN (%s)
            UNION
            SELECT target AS 'identifier' FROM %s WHERE source IN (%s)"
        lbl in_clause lbl in_clause in
    let output = ref IdentifierSet.empty in
    let callback row =
        let id = row |> CCArray.to_list |> CCList.hd |> CCOpt.flat_map Identifier.of_string in match id with
            | Some id -> output := IdentifierSet.add id !output
            | None -> () in
    let _ = Sqlite3.exec_no_headers db ~cb:callback query in
        !output

let get_adjacent_by_view db ids view : IdentifierSet.t =
    View.labels view
        |> CCList.map (get_adjacent_by_label db ids)
        |> CCList.fold_left IdentifierSet.union IdentifierSet.empty

let rec get_nearby_vertices db n ids view : IdentifierSet.t = if n <= 0 then ids else
    let adjacent = get_adjacent_by_view db ids view in
        IdentifierSet.union ids (get_nearby_vertices db (n - 1) adjacent view)

let get_context db n id view : Document.t =
    let id_set = IdentifierSet.singleton id in
    let vertices = get_nearby_vertices db n id_set view in
    let document = IdentifierSet.fold (fun v -> fun doc ->
        let attrs = get_attributes db v (View.attributes view) in
        if Value.Map.is_empty attrs then
            Document.DocGraph.add_vertex doc v
        else
            Document.DocGraph.add_labeled_vertex doc v attrs
    ) vertices Document.DocGraph.empty in
    let pairs = CCList.cartesian_product [IdentifierSet.to_list vertices ; IdentifierSet.to_list vertices]
        |> CCList.filter_map (fun vs -> match vs with
            | x :: y :: [] -> Some (x, y)
            | _ -> None) in
    let edges = pairs
        |> CCList.flat_map (fun (s, d) ->
            let lbls = get_edge_labels db s d view 
                |> CCList.map Value.of_string in
            lbls
                |> CCList.map (fun lbl -> Document.DocGraph.Edge.make_labeled s lbl d)
        ) in
    CCList.fold_left Document.DocGraph.add_edge document edges

let negative db n id view =
    let id_set = IdentifierSet.singleton id in
    let nearby = get_nearby_vertices db n id_set view in
        IdentifierSet.remove id nearby |> IdentifierSet.to_list
