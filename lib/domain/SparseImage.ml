type t = (Matcher.Motif.t * Core.Identifier.t list) list

let to_json img = img
    |> CCList.mapi (fun i -> fun (motif, ids) -> `Assoc [
        ("motif", Matcher.Motif.to_json motif);
        ("index", `Int i);
        ("image", `List (ids |> CCList.map Core.Identifier.to_json))])
    |> fun assocs -> `List assocs