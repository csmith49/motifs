(* references for inputs *)
let problem_filename = ref ""

let doc_filename = ref ""
let ex_filename = ref ""
let positive = ref 0
let quiet = ref false
let negative_width = ref 1
let size = ref 2
let take = ref 3

let spec_list = [
    ("-p", Arg.Set_string problem_filename, "Input problem declaration file");
    ("-d", Arg.Set_string doc_filename, "Input document file");
    ("-l", Arg.Set_string ex_filename, "Input label file");
    ("-p", Arg.Set_int positive, "Single positive example");
    ("-q", Arg.Set quiet, "Sets quiet mode");
    ("-n", Arg.Set_int negative_width, "Sets window for negative examples");
    ("-s", Arg.Set_int size, "Sets max size of synthesized rules");
    ("-t", Arg.Set_int take, "Sets number of top-performing rules to take per view/example")
]

let usage_msg = "I'll set this later"
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
let output_rules = ref []
let rules_per_example = !take

(* what we should do per-example *)
let process (ex : Problem.example) = begin
    let _ = print_string "Loading example data..." in
    let doc = Data.of_string (Problem.file ex) in
    let example = Problem.vertex ex in
    let _ = print_endline "done." in
    let _ = print_endline (Printf.sprintf 
        "Checking vertex %i in %s." 
        example
        (Problem.file ex)) in
    let negative_examples = Data.negative_instances doc !negative_width example view in
    let _ = print_endline (Printf.sprintf "Found %i negative examples." (CCList.length negative_examples)) in
    let rules = Synthesis.filtered_candidates ~max_size:!size doc view example in
    let consistent_rules = CCList.filter (fun r ->
        let q = SQLQuery.of_rule r in
        let img = Data.apply_on doc q negative_examples in
            CCList.is_empty img
    ) rules in
    let rules_w_img_size = CCList.map (fun r ->
        let q = SQLQuery.of_rule r in
        (r, Data.count doc q)
    ) consistent_rules in
    let compare l r = CCInt.compare (snd l) (snd r) in
    let top_rules = rules_w_img_size
        |> CCList.sort compare
        |> CCList.rev
        |> CCList.map fst
        |> CCList.take rules_per_example in
    output_rules := top_rules @ !output_rules
end

(* do the thing per-example *)
let _ = print_endline "Processing examples:"
let _ = CCList.iter process (Problem.examples problem)
let _ = print_endline "Examples processed."