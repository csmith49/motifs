(* references for inputs *)
let doc_filename = ref ""
let ex_filename = ref ""
let positive = ref 0
let quiet = ref false

let spec_list = [
    ("-d", Arg.Set_string doc_filename, "Input document file");
    ("-l", Arg.Set_string ex_filename, "Input label file");
    ("-p", Arg.Set_int positive, "Single positive example");
    ("-q", Arg.Set quiet, "Sets quiet mode")
]

let usage_msg = "I'll set this later"
let _ = Arg.parse spec_list print_endline usage_msg

(* load the data *)
let _ = print_string ("Loading document " ^ !doc_filename ^ "...")
let document = Document.from_file !doc_filename
let _ = print_endline ("done.")

(* loading examples *)
let _ = print_string ("Loading examples from " ^ !ex_filename ^ "...")
let examples = Example.from_file !ex_filename !doc_filename
let _ = print_endline ("done.")

(* get an example *)
let example = CCList.nth examples 2
let _ = print_endline ("Found example: " ^ (Identifier.to_string example))
let _ = print_endline ("Example neighborhood: ")
let ex_neighborhood = Document.DocNeighborhood.n_hop_subgraph 2 example document
let _ = print_endline (
    Document.DocGraph.to_string ex_neighborhood
)

(* synthesize collectors *)
let _ = print_string "Synthesizing rules..."
let rules = Enumeration.candidates_from_example ~max_size:1 example document
let _ = print_endline "done."

(* let's examine the rules *)
let _ = print_endline ("Found " ^ (string_of_int (CCList.length rules)) ^ " rules from example.")
let _ = print_string "Checking rules for consistency..."
let negative = Document.generate_negative example document
let negative_docs = CCList.map (fun n -> Document.DocNeighborhood.n_hop_subgraph 1 n document) negative
let _ = print_string ("found " ^ (string_of_int (CCList.length negative)) ^ " negative examples...")

let rules = CCList.filter (fun r -> 
    let neg_imgs = CCList.flat_map (fun d -> GraphRule.apply r d |> CCList.flatten) negative_docs in
    let consistent = CCList.for_all (fun n -> 
        let ans = not (CCList.mem ~eq:(=) n neg_imgs) in
        let _ = if not ans then 
            let _ = print_endline "Inconsistent rule found:" in
            GraphRule.print r
        else () in
        ans
    ) negative in
    consistent
) rules

let _ = print_endline "done."
let _ = print_endline ("Found " ^ (string_of_int (CCList.length rules)) ^ " consistent rules.")

let _ = print_string "Computing image sizes..."
let image_pairs = CCList.map (fun r ->
    (r, CCList.length (GraphRule.apply r document))
) rules
let _ = print_endline "done."

let largest = CCList.fold_left max 0 (CCList.map snd image_pairs)
let smallest = CCList.fold_left min max_int (CCList.map snd image_pairs)
let _ = print_endline ("Largest image size: " ^ (string_of_int largest))
let _ = print_endline ("Smallest image size: " ^ (string_of_int smallest))

let top_5 = image_pairs
    |> CCList.sort (fun l -> fun r -> CCInt.compare (snd l) (snd r))
    |> CCList.rev
    |> CCList.take 5

let bot_5 = image_pairs
    |> CCList.sort (fun l -> fun r -> CCInt.compare (snd l) (snd r))
    |> CCList.take 5

let _ = print_endline "Top 5 rules:"
let _ = CCList.iter (fun p ->
    let _ = print_endline ("(" ^ (string_of_int (snd p)) ^ ")----------") in
    GraphRule.print (fst p)
) top_5

let _ = print_endline "Bottom 5 rules:"
let _ = CCList.iter (fun p ->
    let _ = print_endline ("(" ^ (string_of_int (snd p)) ^ ")----------") in
    GraphRule.print (fst p)
) bot_5