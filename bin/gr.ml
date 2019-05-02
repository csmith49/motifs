(* references for inputs *)
let problem_filename = ref ""
let output_directory = ref ""
let quiet = ref false
let negative_width = ref 2
let size = ref 2

(* for the REST argument *)
let view_filename = ref ""

let spec_list = [
    ("-p", Arg.Set_string problem_filename, "Input problem declaration file");
    ("-o", Arg.Set_string output_directory, "Output directory");
    ("-q", Arg.Set quiet, "Sets quiet mode");
    ("-n", Arg.Set_int negative_width, "Sets window for negative examples");
    ("-s", Arg.Set_int size, "Sets max size of synthesized rules");
    ("-v", Arg.Set_string view_filename, "Sets view to be used");
]

let usage_msg = "Rule Synthesis for Hera"
let _ = Arg.parse spec_list print_endline usage_msg

(* setup interface *)
module D = Data.Interface.SQLite
module S = Synthesis.Enumeration.SQLMake(D)
module O = Data.SparseJSON.SQLMake(D)

(* load problem declaration *)
let _ = print_string ("Loading problem...")
let problem = Domain.Problem.of_file !problem_filename
let _ = print_endline "done."

(* load views - use cmd line, or default to problem view, or throw exception *)
let _ = print_string ("Loading views...")
let view = if CCString.is_empty !view_filename then
    match Domain.Problem.views problem with
        | Some views -> Domain.View.combine views
        | None -> raise Domain.View.ViewException
    else Domain.View.from_file !view_filename
let _ = print_endline "done."

(* the common variables accessed across all examples *)
let total_rules = 100
let output_rules = ref []
let rules_per_example = total_rules / (CCList.length (Domain.Problem.examples problem))

(* what we should do per-example *)
let process (ex : Domain.Problem.example) = begin
    (* load the example (printing as desired) *)
    let _ = print_string "Loading example data..." in
    let doc = D.of_string (Domain.Problem.file ex) in
    let example = Domain.Problem.vertex ex in
    let _ = print_endline "done." in
    let _ = print_endline (Printf.sprintf 
        "Checking vertex %s in %s:" 
        (Core.Identifier.to_string example)
        (Domain.Problem.file ex)) in

    let context = D.context doc 2 example view in
    let _ = print_endline (Domain.Document.DocGraph.to_string context) in

    (* get negative examples *)
    let negative_examples = D.negative_instances doc !negative_width example view in
    let _ = print_endline (Printf.sprintf "Found %i negative examples." (CCList.length negative_examples)) in

    (* synthesize rules *)
    let rules = S.filtered_candidates ~max_size:!size doc view example in
    let _ = print_endline (Printf.sprintf "Found %i total rules." (CCList.length rules)) in
    
    (* check for consistency *)
    let consistent_rules = CCList.filter (fun r ->
        let q = Data.SQLQuery.of_rule r in
        let img = D.apply_on doc q negative_examples in
            CCList.is_empty img
    ) rules in
    let _ = print_endline (Printf.sprintf "%i consistent rules." (CCList.length consistent_rules)) in

    (* evaluate rules on doc and sort *)
    let _ = print_string "Evaluating rules..." in
    let rules_w_score = CCList.map (fun r ->
        (r, Synthesis.Heuristic.score r)
    ) consistent_rules in
    let _ = print_string "sorting by performance..." in
    let compare l r = CCInt.compare (snd l) (snd r) in
    let top_rules = rules_w_score
        |> CCList.sort compare
        |> CCList.map fst
        |> CCList.take rules_per_example in
    let _ = print_endline "done.\n" in

    (* write output *)
    output_rules := top_rules @ !output_rules
end

(* do the thing per-example *)
let _ = print_endline "Processing examples:\n"
let _ = CCList.iter process (Domain.Problem.examples problem)
let _ = print_endline "Examples processed."

(* print out top 5 rules *)
let _ = print_endline "Top 5 rules:\n"
let _ = CCList.iter (fun r -> 
    Rule.GraphRule.print r; print_endline "\n"
)
(CCList.take 5 (!output_rules))

(* print out bottom 5 rules *)
let _ = print_endline "Bottom 5 rules:\n"
let _ = CCList.iter (fun r -> 
    Rule.GraphRule.print r; print_endline "\n"
)
(CCList.take 5 (!output_rules |> CCList.rev))

(* now write out the rules *)
let write_output filename = begin
    let doc = D.of_string filename in
    let image = O.ensemble_image doc !output_rules in
    let output_file = filename
        |> Filename.basename
        |> Filename.remove_extension 
        |> (fun r -> r ^ ".json") 
        |> Filename.concat !output_directory in
    O.to_file output_file image
end

let _ = print_string "Writing output..."
let _ = if !quiet then () else
    CCList.iter write_output (Domain.Problem.files problem)
let _ = print_endline "done."