type pattern_graph = (Filter.t, Kinder.t) Core.Structure.t

type t = {
    selector : Core.Identifier.t;
    structure : pattern_graph;
}

let pg_to_json = Core.Structure.to_json Filter.to_json Kinder.to_json
let pg_of_json = Core.Structure.of_json Filter.of_json Kinder.of_json

let to_json motif = `Assoc [
    ("selector", Core.Identifier.to_json motif.selector);
    ("structure", pg_to_json motif.structure)
]
let of_json json =
    let selector = Utility.JSON.get "selector" Core.Identifier.of_json json in
    let structure = Utility.JSON.get "structure" pg_of_json json in
    match selector, structure with
        | Some selector, Some structure -> Some {
            selector = selector ; structure = structure
        }
        | _ -> None

let equal left right =
    (* make sure selectors are the same *)
    let selectors_equal = Core.Identifier.equal left.selector right.selector in
    if not selectors_equal then false else
    (* make sure vertices are the same *)
    let lvs = left.structure
        |> Core.Structure.vertices
        |> CCList.sort Core.Identifier.compare in
    let rvs = right.structure
        |> Core.Structure.vertices
        |> CCList.sort Core.Identifier.compare in
    let vertices_equal = CCList.equal Core.Identifier.equal lvs rvs in
    if not vertices_equal then false else
    (* make sure filters are the same *)
    let filters_equal = lvs |> CCList.for_all (fun v ->
        let l_filter = Core.Structure.label v left.structure |> CCOpt.get_exn in
        let r_filter = Core.Structure.label v right.structure |> CCOpt.get_exn in
            Filter.equal l_filter r_filter) in
    if not filters_equal then false else
    (* make sure the edges are the same *)
    let les = left.structure
        |> Core.Structure.edges
        |> CCList.sort (Core.Structure.lift_compare Kinder.compare) in
    let res = right.structure
        |> Core.Structure.edges
        |> CCList.sort (Core.Structure.lift_compare Kinder.compare) in
    let edges_equal = CCList.equal (Core.Structure.lift_equal Kinder.equal) les res in
    edges_equal