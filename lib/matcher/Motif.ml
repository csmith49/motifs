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

let hash = CCHash.poly