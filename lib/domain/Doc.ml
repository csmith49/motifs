type document_graph = (Core.Value.Map.t, Core.Value.t) Core.Structure.t

type t = document_graph

let of_json = Core.Structure.of_json Core.Value.Map.of_json Core.Value.of_json
let to_json = Core.Structure.to_json Core.Value.Map.to_json Core.Value.to_json

let to_string = Core.Structure.to_string
    Core.Value.Map.to_string
    Core.Value.to_string

let to_motif doc identifier =
    let selector = identifier in
    let structure = doc
        |> Core.Structure.map
            Matcher.Filter.of_map
            Matcher.Kinder.of_value in
    {
        Matcher.Motif.selector = selector;
        structure = structure;
    }

let small_window doc pos size =
    let all = Core.Structure.Algorithms.neighborhood doc pos size in
        all |> CCList.filter (fun a -> not (CCList.mem ~eq:Core.Identifier.equal a pos))