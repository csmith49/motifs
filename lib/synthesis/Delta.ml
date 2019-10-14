type vertex_delta = [
    | `Keep
    | `Remove
    | `Weaken of Matcher.Filter.t
]

type edge_delta = [
    | `Keep
    | `Remove
]

(* orderings for deltas *)
let vd_leq left right = match left, right with
    | `Keep, _ -> true
    | _, `Remove -> true
    | `Weaken f, `Weaken f' -> Matcher.Filter.(f => f')
    | _ -> false
let ed_leq left right = match left, right with
    | `Keep, _ -> true
    | _, `Remove -> true
    | _ -> false

let vd_eq left right = match left, right with
    | `Keep, `Keep -> true
    | `Remove, `Remove -> true
    | `Weaken f, `Weaken f' -> Matcher.Filter.equal f f'
    | _ -> false
let ed_eq left right = match left, right with
    | `Keep, `Keep -> true
    | `Remove, `Remove -> true
    | _ -> false

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
    motif_hash : int;
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
    motif_hash = Matcher.Motif.hash motif;
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

(* for partial order heaps *)
let lift_comparison vertex_cmp edge_cmp left right =
    (* make sure we're dealing with the same motif by checking the hash *)
    if left.motif_hash != right.motif_hash then false else
    (* if we are, we have to check if each delta is leq *)
    (* start with vertices *)
    let vertices = structure left |> Core.Structure.vertices in
    let vds_leq = vertices |> CCList.for_all (fun v ->
        let left_vd = VertexMap.get_or v left.vertex_deltas ~default:`Keep in
        let right_vd = VertexMap.get_or v right.vertex_deltas ~default:`Keep in
            vertex_cmp left_vd right_vd) in
    if not vds_leq then false else
    (* then check edges *)
    let edges = structure left |> Core.Structure.edges in
    let eds_leq = edges |> CCList.for_all (fun e ->
        let left_ed = EdgeMap.get_or e left.edge_deltas ~default:`Keep in
        let right_ed = EdgeMap.get_or e right.edge_deltas ~default:`Keep in
            edge_cmp left_ed right_ed) in
    if not eds_leq then false else
        true

(* constructing comparisons *)
let equal = lift_comparison vd_eq ed_eq
let leq = lift_comparison vd_leq ed_leq