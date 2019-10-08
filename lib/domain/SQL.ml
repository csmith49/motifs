type db = Sqlite3.db

let of_string filename = Sqlite3.db_open filename

let rec nearby_nodes db view origin size =
    let query = nearby_nodes_query view origin size in
    let results = ref [] in
    let callback row = match CCArray.get row 0 |> Core.Identifier.of_string with
        | Some id -> results := id :: !results
        | None -> () in
    let _ = Sqlite3.exec_not_null_no_headers db ~cb:callback query in
    !results
and nearby_nodes_query view origin size = Printf.sprintf 
    "WITH RECURSIVE
        connected (source, dest) AS (
            SELECT DISTINCT source, target AS dest FROM
            (%s)
        ),
        step (source, dest) AS (
            SELECT DISTINCT * FROM connected UNION SELECT dest AS source, source AS dest FROM connected
        ),
        transitive (level, node) AS (
            SELECT 1 AS level, source FROM step WHERE source IN (%s) OR dest IN (%s)
            UNION ALL
            SELECT level + 1, B.dest AS node
            FROM transitive AS A JOIN step AS B ON A.node = B.source
            WHERE level <= %i
        )
    SELECT DISTINCT node FROM transitive;"
    (View.labels view 
        |> CCList.map (fun lbl -> Printf.sprintf "SELECT * FROM %s" lbl)
        |> CCString.concat " UNION ")
    (Core.Identifier.to_string origin)
    (Core.Identifier.to_string origin)
    (size)

let rec edges_between db view identifiers =
    let query = edges_between_query view identifiers in
    let results = ref [] in
    let callback row = match row |> CCArray.to_list with
        | [src ; lbl ; dest] ->
            let src = Core.Identifier.of_string src in
            let lbl = Core.Value.of_string lbl in
            let dest = Core.Identifier.of_string dest in
            begin match src, dest with
                | Some src, Some dest -> results := (src, lbl, dest) :: !results
                | _ -> () end
        | _ -> () in
    let _ = Sqlite3.exec_not_null_no_headers db ~cb:callback query in
    !results
and edges_between_query view identifiers =
    let ids = identifiers
        |> CCList.map Core.Identifier.to_string
        |> CCString.concat ", " in
    let where_string = Printf.sprintf "WHERE source IN (%s) OR target IN (%s)" ids ids in
    let convert_label lbl = Printf.sprintf "SELECT source, '%s', target AS dest FROM %s %s" lbl lbl where_string in
    View.labels view
        |> CCList.map convert_label
        |> CCString.concat " UNION "

let rec attributes_for db view identifier =
    let query = attributes_for_query view identifier in
    let results = ref [] in
    let callback row = match row |> CCArray.to_list with
        | [attr ; value] -> results := (attr, Core.Value.of_string value) :: !results
        | _ -> () in
    let _ = Sqlite3.exec_not_null_no_headers db ~cb:callback query in
    !results |> Core.Value.Map.of_list
and attributes_for_query view identifier =
    let select_attr attr = Printf.sprintf "SELECT '%s', value FROM %s WHERE id = %s"
        attr attr (Core.Identifier.to_string identifier) in
    View.attributes view
        |> CCList.map select_attr
        |> CCString.concat " UNION "

(* let get_attributes_query view identifiers = "" *)