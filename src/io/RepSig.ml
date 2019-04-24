module type JSONRepSig = sig
    module Graph : GraphSig.SemanticGraph

    val to_json : Graph.t -> JSON.t
    val of_json : JSON.t -> Graph.t option
end

module type DOTRepSig = sig
    module Graph : GraphSig.SemanticGraph

    type dot

    val graph_to_dot : Graph.t -> dot

    val to_string : dot -> string
    val to_file : string -> dot -> unit
end
