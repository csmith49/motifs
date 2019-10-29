type db = Sqlite3.db

exception SQLException of string
let handle_rc rc = match rc with
    | Sqlite3.Rc.OK -> ()
    | _ as e -> raise (SQLException (Sqlite3.Rc.to_string e))

let run db cb q =
    let rc = Sqlite3.exec_not_null_no_headers db ~cb:cb q in
        handle_rc rc

let of_string filename = Sqlite3.db_open filename

let id_to_column id = Printf.sprintf "_%s" (Core.Identifier.to_string id)

let rec nearby_nodes db view origins size =
    let query = nearby_nodes_query view origins size in
    let results = ref [] in
    let callback row = match CCArray.get row 0 |> Core.Identifier.of_string with
        | Some id -> results := id :: !results
        | None -> () in
    let _ = run db callback query in
    !results @ origins |> CCList.uniq ~eq:Core.Identifier.equal
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
            WHERE level <= %i - 1
        )
    SELECT DISTINCT node FROM transitive;"
    (View.labels view 
        |> CCList.map (fun lbl -> Printf.sprintf "SELECT * FROM %s" lbl)
        |> CCString.concat " UNION ")
    (origin |> CCList.map Core.Identifier.to_string |> CCString.concat ", ")
    (origin |> CCList.map Core.Identifier.to_string |> CCString.concat ", ")
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
    let _ = run db callback query in
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
    let _ = run db callback query in
    !results |> Core.Value.Map.of_list
and attributes_for_query view identifier =
    let select_attr attr = Printf.sprintf "SELECT '%s', value FROM %s WHERE id = %s"
        attr attr (Core.Identifier.to_string identifier) in
    View.attributes view
        |> CCList.map select_attr
        |> CCString.concat " UNION "

(* constructiong document graphs *)
let neighborhood db view identifiers size =
    let nodes = nearby_nodes db view identifiers size in
    let attributes = nodes
        |> CCList.map (attributes_for db view) in
    let edges = edges_between db view nodes in
    Core.Structure.empty
        |> CCList.fold_right2
            Core.Structure.add_vertex nodes attributes
        |> CCList.fold_right
            Core.Structure.add_edge edges

(* convert predicates to subqeuries *)
let predicate_to_subquery = function
    | `Constant (attr, value) -> Printf.sprintf
        "SELECT id FROM %s WHERE value = %s"
        attr
        (Core.Value.to_string value)

(* and filters to combinations of queries *)
let rec filter_to_where_clause = function
    | [] -> "TRUE"
    | pred :: rest ->
        let rest = filter_to_where_clause rest in
        let pred = predicate_to_subquery pred in
        Printf.sprintf "identifier IN (%s) AND %s" pred rest

(* convert vertex to select statement *)
let vertex_to_select_statement id filter = Printf.sprintf
    "SELECT identifier AS %s FROM vertex WHERE %s"
        (id_to_column id) 
        (filter_to_where_clause filter)

(* convert an edge to a select statement *)
let edge_to_select_statement (src, lbl, dest) = match lbl with
    | Matcher.Kinder.Star -> raise Not_found
    | Matcher.Kinder.Constant c -> Printf.sprintf
        "SELECT source AS %s, target AS %s FROM %s"
            (id_to_column src)
            (id_to_column dest)
            (Core.Value.to_string c)

(* evaluating matchers *)
let evaluate db motif =
    let structure = motif.Matcher.Motif.structure in
    let vertex_selects = structure
        |> Core.Structure.vertices
        |> CCList.filter_map (fun id -> match Core.Structure.label id structure with
            | Some lbl -> Some (id, lbl)
            | None -> None)
        |> CCList.map (fun (id, filt) -> vertex_to_select_statement id filt) in
    let edge_selects = structure
        |> Core.Structure.edges
        |> CCList.map edge_to_select_statement in
    let selects = (vertex_selects @ edge_selects)
        |> CCList.map (fun s -> "(" ^ s ^ ")")
        |> CCString.concat " NATURAL JOIN " in
    let query = Printf.sprintf "SELECT DISTINCT %s FROM %s"
        (id_to_column motif.Matcher.Motif.selector)
        (selects) in
    let results = ref [] in
    let callback row = match CCArray.get row 0 |> Core.Identifier.of_string with
        | Some id -> results := id :: !results
        | None -> () in
    let _ = run db callback query in
        !results

let check_consistency db negatives motif =
    let image = evaluate db motif in
    CCList.for_all (fun n -> not (CCList.mem ~eq:Core.Identifier.equal n image)) negatives

let view filename name =
    let view_db = of_string filename in
    (* get the labels *)
    let lbl_q = Printf.sprintf
    "SELECT label FROM (
        SELECT view_id as id, name as label FROM view_label AS V 
            JOIN 
        labels AS L where V.label_id = L.id
        ) as L 
            JOIN 
        views as V 
        ON L.id = V.id where V.name='%s'" name in
    let lbls = ref [] in
    let lbl_cb row =
        let lbl = CCArray.get row 0 in lbls := lbl :: !lbls in
    let _ = run view_db lbl_cb lbl_q in
    (* get the attributes *)
    let attr_q = Printf.sprintf
    "SELECT attribute FROM (
        SELECT view_id as id, name as attribute FROM view_attr AS V 
            JOIN 
        attributes AS A where V.attr_id = A.id
        ) as A
            JOIN 
        views as V 
        ON A.id = V.id where V.name='%s'" name in
    let attrs = ref [] in
    let attr_cb row =
        let attr = CCArray.get row 0 in attrs := attr :: !attrs in
    let _ = run view_db attr_cb attr_q in
    View.empty
        |> View.add_attributes !attrs
        |> View.add_labels !lbls

let apply_shortcut db shortcut =
    let structure = Shortcut.structure shortcut in
    let vertex_selects = structure
        |> Core.Structure.vertices
        |> CCList.filter_map (fun id -> match Core.Structure.label id structure with
            | Some lbl -> Some (id, lbl)
            | None -> None)
        |> CCList.map (fun (id, filt) -> vertex_to_select_statement id filt) in
    let edge_selects = structure
        |> Core.Structure.edges
        |> CCList.map edge_to_select_statement in
    let selects = (vertex_selects @ edge_selects)
        |> CCList.map (fun s -> "(" ^ s ^ ")")
        |> CCString.concat " NATURAL JOIN " in
    let query = Printf.sprintf "SELECT %s FROM %s"
        (structure |> Core.Structure.vertices |> CCList.map id_to_column |> CCString.concat ", ")
        (selects) in
    let results = ref [] in
    let cb row = match Shortcut.concretization_of_row shortcut row with
        | Some conc -> results := conc :: !results
        | None -> () in
    let _ = run db cb query in !results

let shortcut db view shortcuts doc =
    let neighborhood = Core.Structure.vertices doc in
    let new_edges = ref [] in
    let new_vertices = ref [] in
    (* do the thing *)
    let process_shortcut shortcut = begin
        if Shortcut.in_view shortcut view then
            let concretizations = apply_shortcut db shortcut in
            CCList.iter (fun conc ->
                new_vertices := (Shortcut.vertices shortcut conc) @ !new_vertices;
                new_edges := (Shortcut.edges shortcut conc) @ !new_edges;
            ) concretizations
        else ()
    end in
    let _ = CCList.iter process_shortcut shortcuts in
    (* build the result *)
    let result = ref doc in
    let _ = CCList.iter (fun (v, _) ->
        if not (CCList.mem ~eq:Core.Identifier.equal v neighborhood) then
            let lbl = attributes_for db view v in
            result := Core.Structure.add_vertex v lbl !result
    ) !new_vertices in
    let _ = CCList.iter (fun e ->
        if not (CCList.mem ~eq:(Core.Structure.Edge.equal Core.Value.equal) e (Core.Structure.edges doc)) then
            result := Core.Structure.add_edge e !result
    ) !new_edges in
    !result