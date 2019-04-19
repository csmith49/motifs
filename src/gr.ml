(* references for inputs *)
let problem_filename = ref ""
let output_directory = ref ""
let quiet = ref false
let negative_width = ref 2
let size = ref 2

let spec_list = [
    ("-p", Arg.Set_string problem_filename, "Input problem declaration file");
    ("-o", Arg.Set_string output_directory, "Output directory");
    ("-q", Arg.Set quiet, "Sets quiet mode");
    ("-n", Arg.Set_int negative_width, "Sets window for negative examples");
    ("-s", Arg.Set_int size, "Sets max size of synthesized rules");
]

let usage_msg = "Rule Synthesis for Hera"
let _ = Arg.parse spec_list print_endline usage_msg

(* setup interface *)
module Data = Interface.SQLite
module Synthesis = Enumeration.SQLMake(Data)
module Output = SparseJSON.SQLMake(Data)

(* get views - hardcoded for now *)
let _ = print_string ("Loading views...")
let raw_views = [
    "./views/linguistic.json";
    "./views/stylistic.json";
    "./views/syntactic.json";
    "./views/visual.json";
] 
    |> CCList.map View.from_file
let view = View.combine raw_views
let _ = print_endline "done."

(* load problem declaration *)
let _ = print_string ("Loading problem...")
let problem = Problem.of_file !problem_filename
let _ = print_endline "done."

(* the common variables accessed across all examples *)
let total_rules = 100
let output_rules = ref []
let rules_per_example = total_rules / (CCList.length (Problem.examples problem))

(* what we should do per-example *)
let process (ex : Problem.example) = begin
    (* load the example (printing as desired) *)
    let _ = print_string "Loading example data..." in
    let doc = Data.of_string (Problem.file ex) in
    let example = Problem.vertex ex in
    let _ = print_endline "done." in
    let _ = print_endline (Printf.sprintf 
        "Checking vertex %i in %s:" 
        example
        (Problem.file ex)) in

    let context = Data.context doc 1 example view in
    let _ = print_endline (Document.DocGraph.to_string context) in

    (* get negative examples *)
    let negative_examples = Data.negative_instances doc !negative_width example view in
    let _ = print_endline (Printf.sprintf "Found %i negative examples." (CCList.length negative_examples)) in

    (* synthesize rules *)
    let rules = Synthesis.filtered_candidates ~max_size:!size doc view example in
    let _ = print_endline (Printf.sprintf "Found %i total rules." (CCList.length rules)) in
    
    (* check for consistency *)
    let consistent_rules = CCList.filter (fun r ->
        let q = SQLQuery.of_rule r in
        let img = Data.apply_on doc q negative_examples in
            CCList.is_empty img
    ) rules in
    let _ = print_endline (Printf.sprintf "%i consistent rules." (CCList.length consistent_rules)) in

    (* evaluate rules on doc and sort *)
    let _ = print_string "Evaluating rules..." in
    let rules_w_img_size = CCList.map (fun r ->
        let q = SQLQuery.of_rule r in
        (r, Data.count doc q)
    ) consistent_rules in
    let _ = print_string "sorting by performance..." in
    let compare l r = CCInt.compare (snd l) (snd r) in
    let top_rules = rules_w_img_size
        |> CCList.sort compare
        |> CCList.rev
        |> CCList.map fst
        |> CCList.take rules_per_example in
    let _ = print_endline "done.\n" in

    (* write output *)
    output_rules := top_rules @ !output_rules
end

(* do the thing per-example *)
let _ = print_endline "Processing examples:\n"
let _ = CCList.iter process (Problem.examples problem)
let _ = print_endline "Examples processed."

(* print out top 5 rules *)
let _ = print_endline "Top 5 rules:\n"
let _ = CCList.iter (fun r -> 
    GraphRule.print r; print_endline "\n"
)
(CCList.take 5 !output_rules)

(* now write out the rules *)
let write_output filename = begin
    let doc = Data.of_string filename in
    let image = Output.ensemble_image doc !output_rules in
    let output_file = filename
        |> Filename.basename
        |> Filename.remove_extension 
        |> (fun r -> r ^ ".json") 
        |> Filename.concat !output_directory in
    Output.to_file output_file image
end

let _ = print_string "Writing output..."
let _ = if !quiet then () else
    CCList.iter write_output (Problem.files problem)
let _ = print_endline "done."