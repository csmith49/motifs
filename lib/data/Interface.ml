open Signatures
open Domain
open Core

module SQLite : SQLData = struct
    type t = Sqlite3.db

    let of_string filename = Sqlite3.db_open filename

    module DataGraph = Document.DocGraph

    (* utility for defining the things we care about *)
    let get_vertex_attributes db id view =
        let attrs = View.attributes view in
        let check attr =
            let output = ref None in
            let query = Printf.sprintf "SELECT value FROM %s WHERE id = '%s'"
                attr
                (Identifier.to_string id) in
            let callback row =
                let result = CCArray.get_safe row 0 in
                output := CCOpt.flatten result in
            let _ = Sqlite3.exec_no_headers db ~cb:callback query in !output in
        CCList.fold_left (fun m -> fun a -> match check a with
            | Some s -> Value.Map.add a (Value.of_string s) m
            | None -> m) Value.Map.empty attrs
    let get_edge_labels db src dest view =
        let labels = View.labels view in
        let check label =
            let output = ref false in
            let query = Printf.sprintf "SELECT * FROM %s WHERE source = '%s' AND target ='%s'"
                label
                (Identifier.to_string src)
                (Identifier.to_string dest) in
            let callback _ = output := true in
            let _ = Sqlite3.exec_no_headers db ~cb:callback query in !output in
        CCList.filter check labels

    (* sets make everything easier *)
    module IdentifierSet = CCSet.Make(Identifier)

    let get_label_adjacent db ids label =
        let in_clause = ids
            |> IdentifierSet.to_list
            |> CCList.map (fun id -> Printf.sprintf "'%s'" (Identifier.to_string id))
            |> CCString.concat ", " in
        let query = Printf.sprintf
            "SELECT source AS 'identifier' FROM %s WHERE target IN (%s)
                UNION
            SELECT target AS 'identifier' FROM %s WHERE source IN (%s)"
            label in_clause label in_clause in
        let output = ref IdentifierSet.empty in
        let callback row =
            let id = row |> CCArray.to_list |> CCList.hd |> CCOpt.flat_map Identifier.of_string in
            match id with
                | Some id -> output := IdentifierSet.add id !output
                | None -> () in
        let _ = Sqlite3.exec_no_headers db ~cb:callback query in !output
    let get_view_adjacent db ids view =
        let labels = View.labels view in
        labels
            |> CCList.map (get_label_adjacent db ids)
            |> CCList.fold_left IdentifierSet.union IdentifierSet.empty
    let rec nearby_vertices db n ids view = if n <= 0 then ids else
        let step = get_view_adjacent db ids view in
        IdentifierSet.union ids (nearby_vertices db (n - 1) step view)
    
    (* the required stuff *)
    let context db n id view =
        let vertices = nearby_vertices db n (IdentifierSet.singleton id) view in
        let doc = IdentifierSet.fold (fun v -> fun doc ->
            let attrs = get_vertex_attributes db v view in
            if Value.Map.is_empty attrs then
                DataGraph.add_vertex doc v
            else
                DataGraph.add_labeled_vertex doc v attrs
        ) vertices DataGraph.empty in
        let pairs = CCList.cartesian_product [IdentifierSet.to_list vertices ; IdentifierSet.to_list vertices]
            |> CCList.filter_map (fun vs -> match vs with
                | x :: y :: [] -> if x != y then Some (x, y) else None
                | _ -> None) in
        let edges = pairs
            |> CCList.flat_map (fun (s, d) ->
                let labels = get_edge_labels db s d view
                    |> CCList.map Value.of_string in
                labels |> CCList.map (fun lbl -> DataGraph.Edge.make_labeled s lbl d)) in
        CCList.fold_left DataGraph.add_edge doc edges
    
    let negative_instances db n id view =
        let nearby = nearby_vertices db n (IdentifierSet.singleton id) view in
        IdentifierSet.remove id nearby |> IdentifierSet.to_list

    (* for every row, just increment the counter *)
    let count db q =
        let query = SQLQuery.to_sql q in
        let output = ref 0 in
        let callback _ = output := !output + 1 in
        let _ = Sqlite3.exec_no_headers db ~cb:callback query in
            !output

    let apply db q =
        let query = SQLQuery.to_sql q in
        let output = ref [] in
        let callback row header =
            let index =
                let id = q |> SQLQuery.selected |> Identifier.to_string in
                    header |> CCArray.find_idx (fun h -> h = id) |> CCOpt.map fst in
            let result = match index with
                | Some idx -> CCArray.get row idx
                    |> CCOpt.flat_map Identifier.of_string
                | None -> None in
            match result with
                | Some result -> output := result :: !output
                | None -> () in
        let _ = Sqlite3.exec db ~cb:callback query in !output

    let apply_on db ids q =
        let q' = q |> SQLQuery.filter_by ids in apply db q'
end