(* references for inputs *)
let database_filename = ref ""
let output_filename = ref ""
let size = ref 2
let example = ref 0

let spec_list = [
    ("-d", Arg.Set_string database_filename, "Input database file");
    ("-o", Arg.Set_string output_filename, "Output filename");
    ("-e", Arg.Set_int example, "Example to base context around");
    ("-s", Arg.Set_int size, "Context size");
]

let usage_msg = "Constructs .dot file from a selected example"
let _ = Arg.parse spec_list print_endline usage_msg

(* setting up interfaces *)
module Data = Interface.SQLite
module DOT = Representation.DOTRepresentation(Document.DocGraph)

(* open data *)
let data = Data.of_string !database_filename
let ex_vertex = Identifier.of_int !example

(* load views *)
let raw_views = [
    "./views/linguistic.json";
    "./views/stylistic.json";
    "./views/syntactic.json";
    "./views/visual.json";
] 
    |> CCList.map View.from_file
let view = View.combine raw_views

(* get the context *)
let context = Data.context data !size ex_vertex view

(* construct dot representation *)
let dot = DOT.graph_to_dot context

(* write output *)
let _ = DOT.to_file !output_filename dot
