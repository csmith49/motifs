type vertex_delta = [
    | `Keep
    | `Remove
    | `Weaken of Matcher.Filter.t
]

type edge_delta = [
    | `Keep
    | `Remove
]

(* to simplify some types, these are just Motif edges *)
type edge = Core.Identifier.t * Matcher.Kinder.t * Core.Identifier.t

(* helpers for type declaration *)
module VertexMap = CCMap.Make(Core.Identifier)
module EdgeMap = CCMap.Make(struct
    type t = edge

    (* lexicographic comparison *)
    let compare = Core.Structure.lift_compare Matcher.Kinder.compare
end)

type t = {
    base_motif : Matcher.Motif.t;
    vertex_deltas : vertex_delta VertexMap.t;
    edge_deltas : edge_delta EdgeMap.t;
}

(* modify the structure based on the delta *)
let apply motif delta =
    let structure = ref motif.Matcher.Motif.structure in
    let _ = delta.base_motif.Matcher.Motif.structure 
        |> Core.Structure.vertices |> CCList.iter (fun x ->
            match VertexMap.get_or x delta.vertex_deltas ~default:`Keep with
                | `Keep -> ()
                | `Remove ->
                    structure := Core.Structure.remove_vertex x !structure
                | `Weaken f ->
                    structure := Core.Structure.add_vertex x f !structure
            ) in
    let _ = delta.base_motif.Matcher.Motif.structure
        |> Core.Structure.edges |> CCList.iter (fun e ->
            match EdgeMap.get_or e delta.edge_deltas ~default:`Keep with
                | `Keep -> ()
                | `Remove ->
                    structure := Core.Structure.remove_edge ~eq:Matcher.Kinder.equal e !structure
            ) in
    { motif with structure = !structure }

(* apply the deltas to the base motif *)
let concretize delta = apply delta.base_motif delta

let initial motif = {
    base_motif = motif;
    vertex_deltas = VertexMap.empty;
    edge_deltas = EdgeMap.empty;
}

let structure delta = delta.base_motif.Matcher.Motif.structure

(* pick the next vertex or edge to be refined - returns None if one doesn't exist *)
let next_vertex delta =
    let vertices_changed = delta.vertex_deltas
        |> VertexMap.to_list
        |> CCList.map fst in
    let vertices = structure delta |> Core.Structure.vertices in
    CCList.find_opt (fun v -> 
        not (CCList.mem ~eq:Core.Identifier.equal v vertices_changed)) 
    vertices
    
let next_edge delta =
    let edges_changed = delta.edge_deltas
        |> EdgeMap.to_list
        |> CCList.map fst in
    let edges = structure delta |> Core.Structure.edges in
    let eq = Core.Structure.lift_equal Matcher.Kinder.equal in
    CCList.find_opt (fun e -> not (CCList.mem ~eq:eq e edges_changed)) edges

let is_total delta = match next_vertex delta, next_edge delta with
    | None, None -> true
    | _ -> false

let refine delta = match next_vertex delta with
    | Some vertex ->
        let structure = structure delta in
        let deltas = match Core.Structure.label vertex structure with
            | Some filter ->
                let weakened_filters = Matcher.Filter.Lattice.weaken filter in
                `Keep :: `Remove :: (CCList.map (fun f -> `Weaken f) weakened_filters)
            | None -> [] in
        deltas |> CCList.map (fun d -> { 
            delta with vertex_deltas = VertexMap.add vertex d delta.vertex_deltas
        })
    | None -> match next_edge delta with
        | Some edge -> 
            let deltas = `Keep :: `Remove :: [] in
            deltas |> CCList.map (fun d -> { delta with
                edge_deltas = EdgeMap.add edge d delta.edge_deltas
            })
        | None -> []

