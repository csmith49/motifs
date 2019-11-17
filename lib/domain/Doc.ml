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

(* stoplist *)
module Stoplist = struct
    type t = string list
    
    let default = [
        "("; ")"; 
        "["; "]";
        "."; ","; "?"; "!";
        ";";
        " "
    ]

    let contains w sl = CCList.mem ~eq:CCString.equal w sl
end

let remove_stoplist sl doc =
    let result = ref doc in
    let _ = doc
        |> Core.Structure.vertices
        |> CCList.iter (fun v -> match Core.Structure.label v doc with
            | Some attrs -> begin match Core.Value.Map.get "TEXT" attrs with
                | Some (`String s) ->
                    if Stoplist.contains s sl then
                        result := Core.Structure.remove_vertex v !result
                    else ()
                | _ -> ()
            end
            | None -> ())
    in
    !result