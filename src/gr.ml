type test = Interface.SQLite.t

(* references for inputs *)
let doc_filename = ref ""
let ex_filename = ref ""
let positive = ref 0
let quiet = ref false
let negative_width = ref 1
let size = ref 2
let take = ref 3

let spec_list = [
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

(* load the data *)
let _ = print_string ("Loading document " ^ !doc_filename ^ "...")
let data = Data.of_string !doc_filename
let _ = print_endline ("done.")

(* get views *)
let _ = print_string ("Loading views...")
let raw_views = [
    "./views/linguistic.json";
    "./views/stylistic.json";
    "./views/syntactic.json";
    "./views/visual.json";
] 
    |> CCList.map View.from_file
let views = (CCList.cartesian_product [raw_views ; raw_views])
    |> CCList.map View.combine
let _ = print_endline "done."

(* loading examples *)
let _ = print_string ("Loading examples from " ^ !ex_filename ^ "...")
let example_key = !doc_filename |> Filename.basename |> Filename.remove_extension
let _ = print_endline example_key
let all_examples = Example.from_file !ex_filename
let _ = print_endline (CCString.concat ", " (Example.StringMap.to_list all_examples |> CCList.map fst))
let examples = Example.document_examples all_examples example_key
let _ = print_endline ("done.\n")

(* get an example *)
let process example view k = begin
    let _ = print_endline ("Found example: " ^ (Identifier.to_string example)) in

    (* synthesize collectors *)
    let _ = print_string "Synthesizing rules..." in
    let rules = Synthesis.filtered_candidates ~max_size:!size data view example in
    let _ = print_endline "done." in

    (* let's examine the rules *)
    let _ = print_endline ("Found " ^ (string_of_int (CCList.length rules)) ^ " rules from example.") in
    let _ = print_string "Checking rules for consistency..." in
    let negative = Data.negative_instances data !negative_width example view in
    let _ = print_endline ("found " ^ (string_of_int (CCList.length negative)) ^ " negative examples.") in

    let images = CCList.filter_map (fun rule ->
        let _ = print_endline "Checking rule:" in
        let _ = GraphRule.print rule in
        let query = SQLQuery.of_rule rule in
        let image = Data.apply data query in
        if CCList.exists (fun n -> CCList.mem ~eq:(=) n negative) image then
            let _ = print_endline "Rule is inconsistent." in
            None
        else
            let _ = print_endline ("Consistent with image size " ^ (string_of_int (CCList.length image))) in
            Some (rule, image)
    ) rules in

    let _ = print_endline ("\nFound " ^ (string_of_int (CCList.length rules)) ^ " consistent rules.") in

    let top_k = images
        |> CCList.map (fun (k, v) -> (k, CCList.length v))
        |> CCList.sort (fun l -> fun r -> CCInt.compare (snd l) (snd r))
        |> CCList.rev
        |> CCList.take k in

    let _ = print_endline ("Top " ^ (string_of_int k) ^ " rules:") in
    let _ = CCList.iter (fun p ->
        let _ = print_endline ("(" ^ (string_of_int (snd p)) ^ ")----------") in
        GraphRule.print (fst p)
    ) top_k in

    let _ = print_endline "\n-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n" in
    top_k
end

(* process the examples *)
let params = CCList.flat_map (fun e -> CCList.map (fun v -> (e, v)) views) examples
let results = CCList.map (fun (e, v) -> process e v !take) params