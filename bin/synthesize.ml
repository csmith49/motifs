(* references for inputs *)
let problem_filename = ref ""
let output_file = ref "output.json"
let shortcut_filename = ref ""
let strategy = ref "enumerate"
let sample_goal = ref 10
let quiet = ref false
let negative_width = ref 2
let size = ref 2
let yell = ref false

(* arguments for subsampling *)
let max_labels = ref 10
let max_attributes = ref 10

let fixed_labels = ref []
let fixed_attributes = ref []

(* for the REST argument *)
let view_filename = ref ""

(* for outputting stuff *)
let output_amount = ref (-1)

let spec_list = [
    ("-p", Arg.Set_string problem_filename, "Input problem declaration file");
    ("-o", Arg.Set_string output_file, "Output file");
    ("-q", Arg.Set quiet, "Sets quiet mode");
    ("-n", Arg.Set_int negative_width, "Sets window for negative examples");
    ("-s", Arg.Set_int size, "Sets max size of synthesized rules");
    ("-v", Arg.Set_string view_filename, "Sets view to be used");
    ("-y", Arg.Set yell, "Sets yelling on");

    ("--max-labels", Arg.Set_int max_labels, "Sets maximum number of labels to be used (default 10)");
    ("--max-attributes", Arg.Set_int max_attributes, "Sets maximum number of attributes to be used (default 10)");

    ("--shortcut", Arg.Set_string shortcut_filename, "Shortcut file");
    ("--strategy", Arg.Set_string strategy, "Set search strategy");
    ("--sample-goal", Arg.Set_int sample_goal, "Set number of samples desired per example [STRAT: sample]");
    ("--head", Arg.Set_int output_amount, "Set number of motifs to display at the end of the search");
]

let usage_msg = "Rule Synthesis for Hera"
let _ = Arg.parse spec_list print_endline usage_msg

(* load problem declaration *)
let _ = print_string ("Loading problem...")
let problem = Domain.Problem.from_file !problem_filename
let _ = print_endline "done."

(* set the size, if necessary *)
let _ = match Domain.Problem.size problem with
    | Some s -> size := s
    | _ -> ()

(* set the max labels and attributes, if necessary *)
let _ = match Domain.Problem.max_labels problem with
    | Some m -> max_labels := m
    | _ -> ()
let _ = match Domain.Problem.max_attributes problem with
    | Some m -> max_attributes := m
    | _ -> ()

let _ = match Domain.Problem.fixed_labels problem with
    | Some m -> fixed_labels := m
    | _ -> ()
let _ = match Domain.Problem.fixed_attributes problem with
    | Some m -> fixed_attributes := m
    | _ -> ()

(* load views - use cmd line, or default to problem view, or throw exception *)
let _ = print_string ("Loading views...")
let view = if CCString.is_empty !view_filename then
    match Domain.Problem.views problem with
        | Some views -> Domain.View.combine views
        | None -> raise Domain.View.ViewException
    else Domain.View.from_file !view_filename
let _ = Printf.printf "done. Found %d labels and %d attributes.\n"
    (view |> Domain.View.labels |> CCList.length)
    (view |> Domain.View.attributes |> CCList.length)
let _ = Printf.printf "Subsampling views: %d labels and %d attributes\n"
    !max_labels !max_attributes
let view = Domain.View.subsample !max_labels !max_attributes view
    |> Domain.View.add_labels !fixed_labels
    |> Domain.View.add_attributes !fixed_attributes
let _ = Printf.printf "Labels:\n    %s\n" (view |>Domain.View.labels |> CCString.concat "\n    ")
let _ = Printf.printf "Attributes:\n    %s\n" (view |>Domain.View.attributes |> CCString.concat "\n    ")

(* load the shortcuts *)
let _ = print_string "Loading shortcuts..."
let shortcuts = if CCString.is_empty !shortcut_filename then 
    match Domain.Problem.shortcuts problem with
        | Some shortcuts -> shortcuts
        | None -> []
    else Domain.Shortcut.from_file !shortcut_filename
let _ = Printf.printf "done. Found %d shortcuts.\n" (CCList.length shortcuts)

(* the common variables accessed across all examples *)
let output_motifs = ref []

(* what we should do per-example *)
let process (ex : Domain.Problem.example) = begin
    
    (* load the example (printing as desired) *)
    let _ = print_endline "Loading example data..." in
    let db = Domain.SQL.of_string (fst ex) in
    let positive_examples = snd ex in
    let doc = Domain.SQL.neighborhood db view positive_examples !size
        |> Domain.SQL.shortcut db view shortcuts positive_examples in
    let _ = doc |> Domain.Doc.to_string |> print_endline in
    
    let _ = print_endline "...done." in

    (* get negative examples *)
    let negative_examples = Domain.Doc.small_window doc positive_examples !negative_width in
    let _ = Printf.printf "Found negative examples: %s\n" (
        negative_examples |> CCList.map Core.Identifier.to_string |> CCString.concat ", "
        ) in

    (* synthesize rules *)
    let cone = Synthesis.Cone.simple_from_document doc positive_examples in
    let _ = print_endline "Cone constructed. Starting synthesis..." in
    let motifs = match !strategy with
        | s when s = "enumerate" -> Synthesis.Cone.enumerate ~verbose:(!yell) cone
        | s when s = "sample" -> Synthesis.Cone.sample ~count:(!sample_goal) ~verbose:(!yell) cone
        | _ -> [] in
    let _ = print_endline (Printf.sprintf "Found %i total motifs." (CCList.length motifs)) in
    
    (* check for consistency *)
    let consistent_motifs = motifs
        |> CCList.filter (Domain.SQL.check_consistency db negative_examples positive_examples)
    in
    let _ = print_endline (Printf.sprintf "%i consistent motifs." (CCList.length consistent_motifs)) in

    (* write output *)
    output_motifs := consistent_motifs @ !output_motifs
end

(* do the thing per-example *)
let _ = Printf.printf "Found examples:\n\t%s\n"
    (problem |> Domain.Problem.examples |> CCList.map Domain.Problem.example_to_string |> CCString.concat "\n\t")

let _ = print_endline "Processing examples:"
let _ = CCList.iter process (Domain.Problem.examples problem)
let _ = print_endline "Examples processed."

(* now write out the rules *)
let _ = print_string "Writing output...\n"
let output = `List (CCList.map Matcher.Motif.to_json !output_motifs)
let _ = Yojson.Basic.to_file !output_file output
let _ = Printf.printf "done. Output written to %s.\n" !output_file
(* 
(* now write out the rules *)
let _ = print_string "Writing output...\n"
let sparse_image = ref (Domain.SparseImage.of_motifs !output_motifs)
let _ = if !quiet then () else begin
    CCList.iter (fun filename ->
        let db = Domain.SQL.of_string filename in
        let images = CCList.map (Domain.SQL.evaluate db) !output_motifs in
        sparse_image := Domain.SparseImage.add_results filename images !sparse_image
    ) (Domain.Problem.files problem);
    !sparse_image |> Domain.SparseImage.to_json |> Yojson.Basic.to_file !output_file
end
let _ = print_endline "done."

let _ = if !output_amount > 0 then
    let outputs = CCList.take !output_amount !output_motifs in
    outputs |> CCList.iteri (fun i -> fun m ->
        Printf.printf "Solution %d:\n%s\n" i (Matcher.Motif.to_string m)
    ) *)