module DeltaHeap = CCHeap.Make(struct
    type t = Delta.t
    let leq = Delta.PartialOrder.leq
end)

type t = DeltaHeap.t

type enumeration = ?filter:(Delta.t -> bool) -> ?verbose:(bool) -> t -> Matcher.Motif.t list

let from_document doc examples =
    let initial_motifs = examples
        |> CCList.map (fun ex -> Domain.Doc.to_motif doc ex) in
    let joins = Matcher.Motif.PartialOrder.weak_join initial_motifs in
    let deltas = joins
        |> CCList.map Delta.initial in
    DeltaHeap.of_list deltas

let simple_from_document doc examples =
    let initial_motif = Domain.Doc.to_motif doc (examples |> CCList.hd) in
    DeltaHeap.of_list [Delta.initial initial_motif]

let from_examples db view examples size =
    let initial_motifs = examples
        |> CCList.map (fun ex -> (ex, Domain.SQL.neighborhood db view [ex] size))
        |> CCList.map (fun (ex, doc) -> Domain.Doc.to_motif doc ex) in
    let joins = Matcher.Motif.PartialOrder.weak_join initial_motifs in
    let deltas = joins
        |> CCList.map Delta.initial in
    DeltaHeap.of_list deltas

let from_independent_examples db view examples size =
    let initial_motifs = examples
        |> CCList.map (fun ex -> (ex, Domain.SQL.neighborhood db view [ex] size))
        |> CCList.map (fun (ex, doc) -> Domain.Doc.to_motif doc ex) in
    let deltas = initial_motifs
        |> CCList.map Delta.initial in
    DeltaHeap.of_list deltas

let sample_one_change max_nodes max_edges delta =
    let options = delta
        |> Delta.refine
        |> CCList.filter_map (fun r -> CCOpt.Infix.(Some r
            >>= Constraint.keep_selector
            >>= Constraint.max_nodes max_nodes
            >>= Constraint.max_edges max_edges
            >>= Constraint.drop_dangling_edges
            >>= Constraint.stay_connected
            >>= Constraint.attribute_per_node
        )) in
    match options with
        | [] -> None
        | xs -> Some (CCRandom.run (CCRandom.pick_list xs))

let rec sample_no_backtrack max_nodes max_edges delta =
    if Delta.is_total delta then Some delta else
    match sample_one_change max_nodes max_edges delta with
        | None -> None
        | Some result -> sample_no_backtrack max_nodes max_edges result

let sample_from_heap heap = if DeltaHeap.is_empty heap then None else
    Some (CCRandom.run (heap |> DeltaHeap.to_list |> CCRandom.pick_list))

let sample
    ?count:(count=1)
    ?verbose:(verbose=false)
    ?max_nodes:(max_nodes=10)
    ?max_edges:(max_edges=10)
        heap =
    
    (* for printing *)
    let vprint = if verbose then print_endline else (fun _ -> ()) in

    (* we only have a list of solutions we maintain *)
    let solutions = ref [] in

    (* until we have enough solutions, keep getting a new one *)
    while (CCList.length !solutions) < count do
        (* nice printing *)
        let _ = vprint (Printf.sprintf "Starting iteration, %d solutions found" (CCList.length !solutions)) in
        (* get something from the heap *)
        let sample = CCOpt.Infix.(
            sample_from_heap heap >>= sample_no_backtrack max_nodes max_edges
        ) in match sample with
            | Some delta -> 
                let motif = Delta.concretize delta in
                solutions := motif :: !solutions
            | None -> ()
    done;
    !solutions

let enumerate 
    ?filter:(filter=(fun _ -> true))
    ?verbose:(verbose=false)
        heap =
    
    let vprint = if verbose then print_endline else (fun _ -> ()) in

    (* build the in-place resources *)
    let heap = ref heap in
    let solutions = ref [] in
    let count = ref 0 in

    (* enumerate until heap is empty *)
    while not (DeltaHeap.is_empty !heap) do
        let _ = vprint (Printf.sprintf "\n[ITERATION %d]" !count) in
        let _ = count := 1 + !count in
        (* how big is the heap *)
        let _ = vprint (Printf.sprintf "[HEAP SIZE] %d" (!heap |> DeltaHeap.size)) in
        (* get the smallest element *)
        let heap', delta = DeltaHeap.take_exn !heap in
        (* print the motif *)
        let _ = vprint (Printf.sprintf "[BEGIN MOTIF]\n%s\n[END MOTIF]" (
            delta |> Delta.concretize |> Matcher.Motif.to_string
        )) in
        (* transform with checks *)
        let delta = CCOpt.Infix.(Some delta 
            >>= Constraint.keep_selector
            >>= Constraint.max_nodes 4
            >>= Constraint.max_edges 3
            >>= Constraint.drop_dangling_edges
            >>= Constraint.stay_connected
            >>= Constraint.attribute_per_node
        ) in
        match delta with
            | None -> 
                let _ = vprint "[CONSTRAINTS FAILED]" in
                heap := heap'
            | Some delta ->
                let _ = vprint "[CONSTRAINTS PASSED]" in
                (* apply the filter *)
                let filter_result = filter delta in
                (* print if we've passed the filter *)
                (* let _ = vprint (Printf.sprintf "[FILTER CHECK] %b" filter_result) in *)
                let _ = if not filter_result then
                    heap := heap' else
                (* check if it's total, aka can be returned *)
                let is_total = Delta.is_total delta in
                let _ = vprint (Printf.sprintf "[TOTAL?] %b" is_total) in
                let _ = if is_total then
                    solutions := delta :: !solutions in
                (* generate refinements *)
                let refinements = Delta.refine delta in
                let _ = vprint (Printf.sprintf "[REFINEMENTS FOUND] %d" (CCList.length refinements)) in
                (* reconstruct heap *)
                heap := DeltaHeap.add_list heap' refinements
        in vprint "[ITERATION END]"
    done;

    (* return solutions *)
    !solutions |> CCList.rev |> CCList.map Delta.concretize
        |> CCList.uniq ~eq:Matcher.Motif.PartialOrder.equal