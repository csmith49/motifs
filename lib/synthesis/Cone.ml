module DeltaHeap = CCHeap.Make(Delta)

type t = DeltaHeap.t

let from_independent_examples db view examples size =
    let initial_motifs = examples
        |> CCList.map (fun ex -> (ex, Domain.SQL.neighborhood db view [ex] size))
        |> CCList.map (fun (ex, doc) -> Domain.Doc.to_motif doc ex) in
    let deltas = initial_motifs
        |> CCList.map Delta.initial in
    DeltaHeap.of_list deltas

let enumerate ?filter:(filter=(fun _ -> true)) heap =
    (* build the in-place resources *)
    let heap = ref heap in
    let solutions = ref [] in

    (* enumerate until heap is empty *)
    while not (DeltaHeap.is_empty !heap) do
        (* get the smallest element *)
        let heap', delta = DeltaHeap.take_exn !heap in
        (* apply the filter *)
        if not (filter delta) then () else
        (* check if it's total, aka can be returned *)
        let _ = if Delta.is_total delta then
            solutions := delta :: !solutions in
        (* generate refinements *)
        let refinements = Delta.refine delta in
        (* reconstruct heap *)
        let _ = heap := DeltaHeap.add_list heap' refinements in
        ()
    done;

    (* return solutions *)
    !solutions |> CCList.rev |> CCList.map Delta.concretize