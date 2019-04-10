(* references for inputs *)
let doc_filename = ref ""
let ex_filename = ref ""
let positive = ref 0
let quiet = ref false
let negative_width = ref 1
let size = ref 2

let spec_list = [
    ("-d", Arg.Set_string doc_filename, "Input document file");
    ("-l", Arg.Set_string ex_filename, "Input label file");
    ("-p", Arg.Set_int positive, "Single positive example");
    ("-q", Arg.Set quiet, "Sets quiet mode");
    ("-n", Arg.Set_int negative_width, "Sets window for negative examples");
    ("-s", Arg.Set_int size, "Sets max size of synthesized rules")
]

let usage_msg = "I'll set this later"
let _ = Arg.parse spec_list print_endline usage_msg

(* load the data *)
let _ = print_string ("Loading document " ^ !doc_filename ^ "...")
let data = SQLite.of_filename !doc_filename
let _ = print_endline ("done.")

(* get views *)
let _ = print_string ("Loading views...")
let view = [
    "./views/linguistic.json";
    "./views/stylistic.json";
    "./views/syntactic.json";
    "./views/visual.json";
] 
    |> CCList.map View.from_file
    |> View.combine
let _ = print_endline "done."



(* test rule *)
let filter = Filter.Make.of_string "PARENT_OF"
let rule = GraphRule.Make.singleton 1
    |> GraphRule.Make.add_vertex 2
    |> GraphRule.Make.add_vertex 3
    |> GraphRule.Make.add_edge 1 filter 2
    |> GraphRule.Make.add_edge 1 filter 3
let query = GraphRule.Query.of_rule rule
let _ = print_endline (GraphRule.Query.to_string query)

let data = SQLite.apply_query data query
let _ = print_endline (string_of_int (CCList.length data))

(* loading examples *)
(* let _ = print_string ("Loading examples from " ^ !ex_filename ^ "...")
let examples = Example.from_file !ex_filename !doc_filename
let _ = print_endline ("done.\n") *)

(* get an example *)
(* let process_example example = begin
    let _ = print_endline ("Found example: " ^ (Identifier.to_string example)) in
    let _ = print_endline ("Example neighborhood: ") in
    let ex_neighborhood = Document.DocNeighborhood.n_hop_subgraph 2 example document in
    let _ = print_endline ((
        Document.DocGraph.to_string ex_neighborhood
    ) ^ "\n") in

    (* synthesize collectors *)
    let _ = print_string "Synthesizing rules..." in
    let rules = Enumeration.candidates_from_example ~max_size:!size example document in
    let _ = print_endline "done." in

    (* let's examine the rules *)
    let _ = print_endline ("Found " ^ (string_of_int (CCList.length rules)) ^ " rules from example.") in
    let _ = print_string "Checking rules for consistency..." in
    let negative = Document.generate_negative !negative_width example document in
    let negative_docs = CCList.map (fun n -> 
        Document.DocNeighborhood.n_hop_subgraph !size n document
    ) negative in
    let _ = print_endline ("found " ^ (string_of_int (CCList.length negative)) ^ " negative examples.") in

    let rules = CCList.filter (fun r -> 
        let neg_imgs = CCList.flat_map (fun d -> GraphRule.apply r d |> CCList.flatten) negative_docs in
        let consistent = CCList.for_all (fun n -> 
            let ans = not (CCList.mem ~eq:(=) n neg_imgs) in
            let _ = if not ans then 
                let _ = print_endline "\nInconsistent rule found:" in
                GraphRule.print r
            else () in
            ans
        ) negative in
        consistent
    ) rules in

    let _ = print_endline ("\nFound " ^ (string_of_int (CCList.length rules)) ^ " consistent rules.") in

    let small_document = Document.DocNeighborhood.n_hop_subgraph 6 example document in
    let _ = print_endline ("\nRestricting document to " ^ (string_of_int (CCList.length (Document.DocGraph.vertices small_document))) ^ " nodes.\n") in

    let _ = print_string "Computing image sizes..." in
    let image_pairs = CCList.map (fun r ->
        (r, CCList.length (GraphRule.apply r small_document))
    ) rules in
    let _ = print_endline "done." in

    let largest = CCList.fold_left max 0 (CCList.map snd image_pairs) in
    let smallest = CCList.fold_left min max_int (CCList.map snd image_pairs) in
    let _ = print_endline ("Largest image size: " ^ (string_of_int largest)) in
    let _ = print_endline ("Smallest image size: " ^ (string_of_int smallest)) in

    let top_5 = image_pairs
        |> CCList.sort (fun l -> fun r -> CCInt.compare (snd l) (snd r))
        |> CCList.rev
        |> CCList.take 5 in

    let bot_5 = image_pairs
        |> CCList.sort (fun l -> fun r -> CCInt.compare (snd l) (snd r))
        |> CCList.take 5 in

    let _ = print_endline "Top 5 rules:" in
    let _ = CCList.iter (fun p ->
        let _ = print_endline ("(" ^ (string_of_int (snd p)) ^ ")----------") in
        GraphRule.print (fst p)
    ) top_5 in

    let _ = print_endline "Bottom 5 rules:" in
    let _ = CCList.iter (fun p ->
        let _ = print_endline ("(" ^ (string_of_int (snd p)) ^ ")----------") in
        GraphRule.print (fst p)
    ) bot_5 in
    print_endline "\n-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n"
end

(* process the examples *)
let _ = CCList.iter process_example examples *)