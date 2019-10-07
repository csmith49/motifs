open Core

(* predicates are filters applied to particular attributes *)

module Clause = struct
    type t = {
        attribute : string;
        filter : Filter.t;
    }

    let clause s f = {
        attribute = s;
        filter = f;
    }

    let attribute c = c.attribute
    let filter c = c.filter

    let to_string c = Printf.sprintf "%s @ %s" (Filter.to_string c.filter) (c.attribute)

    let apply c m = match Value.Map.get c.attribute m with
        | Some value -> Filter.apply c.filter value
        | _ -> false

    let to_json c = `Assoc [
        ("attribute", `String c.attribute);
        ("filter", Filter.to_json c.filter)
    ]
    let of_json json =
        let attribute = json
            |> JSON.assoc "attribute"
            |> CCOpt.flat_map JSON.to_string_lit in
        let filter = json
            |> JSON.assoc "filter"
            |> CCOpt.flat_map Filter.of_json in
        match attribute, filter with
            | Some attr, Some f -> Some {
                attribute = attr;
                filter = f;
            }
            | _ -> None

    let weaken c =
        let weakenings = Filter.Weaken.greedy c.filter in
        CCList.map (fun w -> {c with filter = w}) weakenings

    let from_clause clause =
        let tbl = attribute clause in
        let condition = filter clause |> Filter.where_clause_body in
            Printf.sprintf "FROM %s WHERE %s" tbl condition
end

type t = Clause.t list

let clauses p = p
let clause_by_idx pred idx =
    CCList.get_at_idx idx pred

let of_list clauses = clauses
let singleton clause = [clause]

let to_string p = p
    |> CCList.map Clause.to_string
    |> CCString.concat " & "

let apply p m = p |> CCList.for_all (fun c -> Clause.apply c m)

(* json manipulation *)
let to_json p =
    let clauses = p
        |> CCList.map Clause.to_json in
    `List clauses
let of_json json = json
    |> JSON.flatten_list
    |> CCList.map Clause.of_json
    |> CCOpt.sequence_l