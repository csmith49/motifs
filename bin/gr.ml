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


(* load problem declaration *)
let _ = print_string ("Loading problem...")
let problem = Domain.Problem.from_file !problem_filename
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
let rules_per_example = 
    total_rules / (CCList.length (Domain.Problem.examples problem))

(* what we should do per-example *)
let process (ex : Domain.Problem.example) = begin
    
    (* load the example (printing as desired) *)
    let _ = print_string "Loading example data..." in
    let db = Domain.SQL.of_string (fst ex) in
    let node = snd ex in
    
    let _ = print_endline "done." in
    let _ = print_endline (Printf.sprintf 
        "Checking vertex %s in %s:" 
        (Core.Identifier.to_string node)
        (fst ex)) in

    (* get negative examples *)
    let negative_examples = [] in

    (* synthesize rules *)
    let motifs = [] in
    let _ = print_endline (Printf.sprintf "Found %i total motifs." (CCList.length motifs)) in
    
    (* check for consistency *)
    let check_consistency motif =
        let img = Domain.SQL.evaluate db motif in
        negative_examples
            |> CCList.inter ~eq:Core.Identifier.equal img
            |> CCList.is_empty in
    let consistent_motifs = motifs
        |> CCList.filter check_consistency in
    let _ = print_endline (Printf.sprintf "%i consistent motifs." (CCList.length consistent_motifs)) in

    (* write output *)
    output_rules := consistent_motifs @ !output_rules
end

(* do the thing per-example *)
let _ = print_endline "Processing examples:\n"
let _ = CCList.iter process (Domain.Problem.examples problem)
let _ = print_endline "Examples processed."

(* now write out the rules *)
let write_output filename = begin
    let db = Domain.SQL.of_string filename in
    let sparse_image = !output_rules
        |> CCList.map (fun motif -> (motif, Domain.SQL.evaluate db motif)) in
    let output_file = filename
        |> Filename.basename
        |> Filename.remove_extension
        |> (fun r -> r ^ ".json")
        |> Filename.concat !output_directory in
    sparse_image
        |> Domain.SparseImage.to_json
        |> Yojson.Basic.to_file output_file
end

let _ = print_string "Writing output..."
let _ = if !quiet then () else
    CCList.iter write_output (Domain.Problem.files problem)
let _ = print_endline "done."