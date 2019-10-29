(* base type *)
type t = (Core.Value.Map.t, Core.Value.t) Core.Structure.t

(* conversion *)
let of_json = Core.Structure.of_json
    Core.Value.Map.of_json
    Core.Value.of_json

let from_file filename =
    let json = Yojson.Basic.from_file filename in
    (Utility.JSON.list of_json) json
        |> CCOpt.get_or ~default:[]

(* concretization stuff *)
type concretization = (Core.Identifier.t * Core.Identifier.t) list

let concretization_of_row shortcut row =
    let vertices = Core.Structure.vertices shortcut in
    row |> CCArray.to_list |> CCList.map2 CCPair.make vertices
        |> CCList.map (fun (v, s) -> match Core.Identifier.of_string s with
            | Some i -> Some (v, i)
            | None -> None)
        |> CCList.all_some
let intersects_neighborhood conc neighborhood =
    let image = CCList.map snd conc in
    CCList.exists (fun i -> CCList.mem ~eq:Core.Identifier.equal i neighborhood) image

(* concrete vertex and edge production *)
let lookup v conc = CCList.assoc_opt ~eq:Core.Identifier.equal v conc
let vertices shortcut conc = conc
    |> CCList.filter_map (fun (s, c) -> match Core.Structure.label s shortcut with
        | Some lbl -> Some (c, lbl)
        | None -> None)
let edges shortcut conc = shortcut
    |> Core.Structure.edges
    |> CCList.filter_map (fun e ->
        let src = Core.Structure.Edge.source e in
        let dest = Core.Structure.Edge.destination e in
        let lbl = Core.Structure.Edge.label e in
        match lookup src conc, lookup dest conc with
            | Some src, Some dest -> Some (src, lbl, dest)
            | _ -> None
    )

(* convert to a structure *)
let structure = Core.Structure.map
    Matcher.Filter.of_map
    Matcher.Kinder.of_value

(* check if the structure is in a view *)
(* let attributes shortcut = shortcut
    |> Core.Structure.vertices
    |> CCList.filter_map (fun v ->
        Core.Structure.label v shortcut
    )
    |> CCList.flat_map (fun m -> m
        |> Core.Value.Map.to_list
        |> CCList.map fst)
let labels shortcut = shortcut
    |> Core.Structure.edges
    |> CCList.map Core.Structure.Edge.label
    |> CCList.map Core.Value.to_string *)

(* let contains small big = CCList.for_all (fun s ->
    CCList.mem ~eq:CCString.equal s big
) small *)

(* let in_view shortcut view =
    let attrs = View.labels view in
    let _ = print_endline (CCString.concat ", " attrs) in
    (* check if all the attributes are in the view *)
    if contains (attributes shortcut) (View.attributes view) then
        contains (labels shortcut) (View.labels view)
    else false *)

let in_view _ _ = true