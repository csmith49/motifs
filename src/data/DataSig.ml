open GraphSig

module type Data = sig
    (* representing a view of the data *)
    type t
    type vertex
    type graph
    type query

    val of_string : string -> t

    module DataGraph : SemanticGraph with
        type vertex = vertex

    val context : t -> int -> vertex -> DataGraph.t

    val negative_instances : t -> int -> vertex -> vertex list

    val count : t -> query -> int
    val apply : t -> query -> vertex list

    val apply_on : t -> query -> vertex list -> vertex list
end