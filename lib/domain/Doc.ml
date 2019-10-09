type document_graph = (Core.Value.Map.t, Core.Value.t) Core.Structure.t

type t = document_graph

let of_json = Core.Structure.of_json Core.Value.Map.of_json Core.Value.of_json
let to_json = Core.Structure.to_json Core.Value.Map.to_json Core.Value.to_json

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

(* for applying a small window, we convert to sets in the interim *)
module IdentSet = CCSet.Make(Core.Identifier)

let src (src, _, _) = src
let dest (_, _, dest) = dest 
let one_away doc id =
    let succ = doc
        |> Core.Structure.outgoing id
        |> CCList.map dest in
    let prec = doc
        |> Core.Structure.incoming id
        |> CCList.map src in
    succ @ prec
        |> IdentSet.of_list

let rec small_window doc initial size =
    small_window_aux doc (IdentSet.of_list initial) size
        |> IdentSet.to_list
and small_window_aux doc initial size =
    if size <= 0 then initial
    else let one_step = 
        IdentSet.fold (fun id -> fun set -> IdentSet.union set (one_away doc id)) initial initial in
        if size = 1 then one_step else small_window_aux doc one_step (size - 1)
