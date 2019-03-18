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

let attributes = Document.NodeMap.get_or ~default:Value.Map.empty !positive document.Document.attributes
let _ = print_endline (Value.Map.to_string attributes)

