(* references for inputs *)
let dataset_filename = ref ""
let image_index = ref 0
let quiet = ref false
let size = ref 1

(* for the REST argument *)
let view_filename = ref ""

let spec_list = [
    ("-i", Arg.Set_int image_index, "Image index to caption");
    ("-q", Arg.Set quiet, "Sets quiet mode");
    ("-s", Arg.Set_int size, "Sets max size of synthesized rules");
    ("-d", Arg.Set_string dataset_filename, "Location of CLEVR dataset");
]

let usage_msg = "Entity Extraction for CLEVR Dataset"
let _ = Arg.parse spec_list print_endline usage_msg

(* setup interface *)
module D = Data.Interface.SQLite
module S = Synthesis.Enumeration.SQLMake(D)
module O = Data.SparseJSON.SQLMake(D)

(* load the database as a uniform doc *)
let _ = print_string (Printf.sprintf "Loading data from %s..." !dataset_filename)
let doc = D.of_string !dataset_filename
let _ = print_endline "done."

(* load views - use cmd line, or default to problem view, or throw exception *)
let _ = print_string ("Loading view...")
let view = Domain.View.from_file "./views/clevr.json"
let _ = print_endline "done."

(* get objects in image *)
let objects = D.scene doc !image_index
let _ = print_endline (Printf.sprintf "Image %n has %n objects." !image_index (CCList.length objects))

(* generate per-object caption *)
let caption obj =
    let _ = print_endline (Printf.sprintf "Processing object %s..." (Core.Identifier.to_string obj)) in 
    let context = D.context doc 2 obj view in
    let _ = print_endline (Domain.Document.DocGraph.to_string context) in
    (* synthesize *)
    let rules = S.filtered_candidates ~max_size:!size doc view obj in
    let _ = print_endline (Printf.sprintf "found %i total rules." (CCList.length rules)) in
    (* pull negative examples *)
    let negative_examples = CCList.remove ~eq:Core.Identifier.equal ~key:obj objects in
    (* check for consistency *)
    let _ = print_endline "Checking consistency..." in
    let consistent_rules = CCList.filter (fun r ->
        let q = Data.SQLQuery.of_rule r in
        let img = D.apply_on doc q negative_examples in
            CCList.is_empty img
        ) rules in
    let _ = print_endline (Printf.sprintf "%i consistent rules." (CCList.length consistent_rules)) in
    (* sort and pick the best *)
    let _ = print_string "Evaluating rules..." in
    let rules_w_score = CCList.map (fun r -> (r, Synthesis.Heuristic.score r)) consistent_rules in
    let _ = print_string "sorting by performance..." in
    let compare l r = CCInt.compare (snd l) (snd r) in
    let top_rule = rules_w_score
        |> CCList.sort compare
        |> CCList.map fst
        |> CCList.head_opt in
    let _ = print_endline "done.\n" in
    top_rule

(* process each object *)
let _ = print_endline "Processing examples:\n"
let captions = CCList.map caption objects
let _ = print_endline "Captions generated.\n"

(* print the summary *)
let found_captions = captions
    |> CCList.filter_map (fun x -> x)
let unfound = (CCList.length captions) - (CCList.length found_captions)
let _ = print_endline (Printf.sprintf "%n objects without a caption." unfound)
let _ = print_endline "Summary:"
let _ = CCList.iter (fun r ->
    Rule.GraphRule.print r; print_endline "\n"
) found_captions
