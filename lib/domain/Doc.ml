type document_graph = (Core.Value.Map.t, Core.Value.t) Core.Structure.t

type t = document_graph

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