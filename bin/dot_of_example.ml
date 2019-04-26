(* references for inputs *)
let database_filename = ref ""
let output_filename = ref "out.dot"
let size = ref 2
let example = ref 0
let view = ref ""

let spec_list = [
    ("-d", Arg.Set_string database_filename, "Input database file");
    ("-o", Arg.Set_string output_filename, "Output filename");
    ("-e", Arg.Set_int example, "Example to base context around");
    ("-s", Arg.Set_int size, "Context size");
    ("-v", Arg.Set_string view, "View to use");
]

let usage_msg = "Constructs .dot file from a selected example"
let _ = Arg.parse spec_list print_endline usage_msg

(* setting up interfaces *)
module D = Data.Interface.SQLite
module DOT = Graph.Representation.DOTRepresentation(Domain.Document.DocGraph)

(* open data *)
let data = D.of_string !database_filename
let ex_vertex = Core.Identifier.of_int !example

(* load views *)
let raw_view = !view
    |> Domain.View.from_file
let view = Domain.View.combine [raw_view]

(* get the context *)
let context = D.context data !size ex_vertex view

(* construct dot representation *)
let dot = DOT.graph_to_dot context

(* write output *)
let _ = DOT.to_file !output_filename dot
