open Core
open Rule

module IdentifierSet = CCSet.Make(Identifier)

type table = string
type query = string

type t = {
    tables : table list;
    selected : Identifier.t;
}

let of_string : string -> t = fun str -> {
    tables = [str];
    selected = Identifier.of_int 0;
}

let selected q = q.selected

let table_of_edge : GraphRule.RuleGraph.edge -> table = fun e -> Printf.sprintf
    "SELECT source AS '%s', destination AS '%s' FROM %s"
        (e |> GraphRule.RuleGraph.Edge.source |> Identifier.to_string)
        (e |> GraphRule.RuleGraph.Edge.destination |> Identifier.to_string)
        (e |> GraphRule.RuleGraph.Edge.label |> CCOpt.get_exn |> Value.to_string)

let table_of_vertex_opt : GraphRule.RuleGraph.t -> Identifier.t -> table option =
    fun g -> fun v -> match GraphRule.RuleGraph.label g v  with
        | Some predicate -> begin match Predicate.clauses predicate with
            | [] -> None
            | clause :: _ -> Some (
                Printf.sprintf "SELECT object as '%s' %s"
                    (Identifier.to_string v)
                    (Predicate.Clause.from_clause clause)
            )
        end
        | None -> None

let tables_of_graph : GraphRule.RuleGraph.t -> table list = fun g ->
    let edge_queries = g
        |> GraphRule.RuleGraph.edges
        |> CCList.map table_of_edge in
    let vertex_queries = g
        |> GraphRule.RuleGraph.vertices
        |> CCList.filter_map (table_of_vertex_opt g) in
    edge_queries @ vertex_queries

let of_rule : GraphRule.t -> t = fun rule -> {
    tables = tables_of_graph rule.GraphRule.graph;
    selected = rule.selected;
}

let filter_by : t -> Identifier.t list -> t = fun q -> fun ids ->
    let filter_table = Printf.sprintf
        "SELECT object AS '%s' FROM objects WHERE object IN (%s)"
        (q.selected |> Identifier.to_string)
        (ids
            |> CCList.map Identifier.to_string
            |> CCList.map (fun s -> "'" ^ s ^ "'")
            |> CCString.concat ", "
        ) in { q with tables = filter_table :: q.tables }

let to_sql : t -> query = fun q ->
    let wrapped_tables = q.tables
        |> CCList.map (fun t -> "(" ^ t ^ ")") in
    Printf.sprintf "SELECT * FROM %s"
        (CCString.concat " NATURAL JOIN " wrapped_tables)