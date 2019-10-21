module DeltaHeap = CCHeap.Make(struct
    type t = Delta.t
    let leq = Delta.PartialOrder.leq
end)

type t = DeltaHeap.t

type enumeration = ?filter:(Delta.t -> bool) -> ?verbose:(bool) -> t -> Matcher.Motif.t list

let from_independent_examples db view examples size =
    let initial_motifs = examples
        |> CCList.map (fun ex -> (ex, Domain.SQL.neighborhood db view [ex] size))
        |> CCList.map (fun (ex, doc) -> Domain.Doc.to_motif doc ex) in
    let deltas = initial_motifs
        |> CCList.map Delta.initial in
    DeltaHeap.of_list deltas

let enumerate 
    ?filter:(filter=(fun _ -> true))
    ?verbose:(verbose=false)
        heap =
    
    let vprint = if verbose then print_endline else (fun _ -> ()) in

    (* build the in-place resources *)
    let heap = ref heap in
    let solutions = ref [] in

    (* enumerate until heap is empty *)
    while not (DeltaHeap.is_empty !heap) do
        let _ = vprint "\n[ITERATION START]" in

        (* how big is the heap *)
        let _ = vprint (Printf.sprintf "[HEAP SIZE] %d" (!heap |> DeltaHeap.size)) in

        (* get the smallest element *)
        let heap', delta = DeltaHeap.take_exn !heap in

        (* print the motif *)
        let _ = vprint (Printf.sprintf "[BEGIN MOTIF]\n%s\n[END MOTIF]" (
            delta |> Delta.concretize |> Matcher.Motif.to_string
        )) in

        (* apply the filter *)
        let filter_result = filter delta in

        (* print if we've passed the filter *)
        let _ = vprint (Printf.sprintf "[FILTER CHECK] %b" filter_result) in

        let _ = if not filter_result then
            heap := heap'
        else
            (* check if it's total, aka can be returned *)
            let is_total = Delta.is_total delta in

            let _ = vprint (Printf.sprintf "[TOTAL?] %b" is_total) in

            let _ = if is_total then
                solutions := delta :: !solutions in
            
            (* generate refinements *)
            let refinements = Delta.refine ~verbose:verbose delta in

            let _ = vprint (Printf.sprintf "[REFINEMENTS FOUND] %d" (CCList.length refinements)) in

            (* reconstruct heap *)
            heap := DeltaHeap.add_list heap' refinements
        
        in vprint "[ITERATION END]"
    done;

    (* return solutions *)
    !solutions |> CCList.rev |> CCList.map Delta.concretize