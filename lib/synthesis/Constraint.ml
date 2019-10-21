type checker = Delta.t -> Delta.t option

(* make sure we're not dropping the selector *)
let keep_selector delta =
    let selector = (Delta.motif delta).Matcher.Motif.selector in
    if CCList.mem ~eq:Delta.PartialOrder.entry_eq (Delta.V selector, `Remove) (Delta.changes delta) then
        None
    else Some delta

(* make sure we remove edges when dropping a vertex *)
let is_vertex_drop change = match change with
    | Delta.V _, `Remove -> true
    | _ -> false
let drop_dangling_edges delta =
    let structure = (Delta.motif delta).Matcher.Motif.structure in
    let dropped_vertices = Delta.changes delta
        |> CCList.filter is_vertex_drop
        |> CCList.map fst
        |> CCList.filter_map (fun i -> match i with Delta.V v -> Some v | _ -> None) in
    let get_dangling v = (Core.Structure.incoming v structure) @ (Core.Structure.outgoing v structure) in
    let dangling_edges = CCList.flat_map get_dangling dropped_vertices
        |> CCList.map (fun e -> Delta.E e, `Remove) in
    Delta.add_changes delta dangling_edges

(* make sure we stay connected as we drop edges *)
let stay_connected delta =
    let concretized = Delta.concretize delta in
    let selector = concretized.Matcher.Motif.selector in
    let structure = concretized.Matcher.Motif.structure in
    (* check what's reachable from the selector *)
    let reachable = Core.Structure.Algorithms.bireachable structure [selector] in
    let unreachable = Core.Structure.vertices structure
        |> CCList.filter (fun v -> not (CCList.mem ~eq:Core.Identifier.equal v reachable)) in
    let dangling_edges = Core.Structure.edges structure
        |> CCList.filter (fun e ->
            (CCList.mem ~eq:Core.Identifier.equal (Core.Structure.Edge.source e) unreachable) ||
            (CCList.mem ~eq:Core.Identifier.equal (Core.Structure.Edge.destination e) unreachable)) in
    let vertex_changes = unreachable
        |> CCList.map (fun v -> Delta.V v, `Remove) in
    let edge_changes = dangling_edges
        |> CCList.map (fun e -> Delta.E e, `Remove) in
    Delta.add_changes delta (vertex_changes @ edge_changes)