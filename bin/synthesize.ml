(* references for inputs *)
let problem_filename = ref ""
let output_directory = ref ""
let shortcut_filename = ref ""
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

let spec_list = [
    ("-p", Arg.Set_string problem_filename, "Input problem declaration file");
    ("-o", Arg.Set_string output_directory, "Output directory");
    ("-q", Arg.Set quiet, "Sets quiet mode");
    ("-n", Arg.Set_int negative_width, "Sets window for negative examples");
    ("-s", Arg.Set_int size, "Sets max size of synthesized rules");
    ("-v", Arg.Set_string view_filename, "Sets view to be used");
    ("-y", Arg.Set yell, "Sets yelling on");

    ("-ml", Arg.Set_int max_labels, "Sets maximum number of labels to be used (default 10)");
    ("-ma", Arg.Set_int max_attributes, "Sets maximum number of attributes to be used (default 10)");

    ("-shortcut", Arg.Set_string shortcut_filename, "Shortcut file");
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
        |> Domain.SQL.shortcut db view shortcuts in
    let _ = doc |> Domain.Doc.to_string |> print_endline in
    
    let _ = print_endline "...done." in

    (* get negative examples *)
    let negative_examples = Domain.Doc.small_window doc positive_examples !negative_width in
    let _ = Printf.printf "Found negative examples: %s\n" (
        negative_examples |> CCList.map Core.Identifier.to_string |> CCString.concat ", "
        ) in

    (* synthesize rules *)
    let motifs = Synthesis.Cone.from_examples db view positive_examples !size
        |> Synthesis.Cone.enumerate
            (* ~filter:(fun d -> 
                let m = d |> Synthesis.Delta.concretize in
                Matcher.Motif.well_connected m && Matcher.Motif.well_formed m) *)
            ~verbose:(!yell)
    in
    let _ = print_endline (Printf.sprintf "\nFound %i total motifs." (CCList.length motifs)) in
    
    (* check for consistency *)
    let consistent_motifs = motifs
        |> CCList.filter (Domain.SQL.check_consistency db negative_examples)
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
let write_output filename = begin
    let db = Domain.SQL.of_string filename in
    let sparse_image = !output_motifs
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