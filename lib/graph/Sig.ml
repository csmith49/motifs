module type GRAPH = sig
    type ('vl, 'el) t
    type vertex

    module Vertex : sig
        type t
        val equal : t -> t -> bool
    end with type t = vertex

    type 'el edge = vertex * 'el * vertex
    type ('vl, 'el) context
    
    val mem : ('vl, 'el) t -> vertex -> bool
    val context : ('vl, 'el) t -> vertex -> ('vl, 'el) context option

    val label : ('vl, 'el) context -> 'vl
    val in_edges : ('vl, 'el) context -> 'el edge list
    val out_edges : ('vl, 'el) context -> 'el edge list

    val vertices : ('vl, 'el) t -> vertex list
    val contexts : ('vl, 'el) t -> ('vl, 'el) context
    val edges : ('vl, 'el) t -> 'el edge list
end


module type JSONREPRESENTABLE = sig
    type t

    (* should be able to convert to/from json reps *)
    val to_json : t -> Yojson.Basic.t
    val of_json : Yojson.Basic.t -> t option
end

module type VERTEX = sig
    type t
    include JSONREPRESENTABLE with type t := t
end

module type EDGE = sig
    type t
    type vertex
    type label

     val source : t -> vertex
    val destination : t -> vertex
    val label : t -> label
end

module type VERTEXLABEL = sig
    type t
    include JSONREPRESENTABLE with type t := t
end

module type EDGELABEL = sig
    type t
    include JSONREPRESENTABLE with type t := t
end

module type GRAPH = sig
    (* graph representation is abstract *)
    type t

    (* but we know we have vertices and edges *)
    type vertex
    type edge

    (* and vertex and edge labels *)
    type vertex_label
    type edge_label

    (* with modules for easy manipulation of vertices and edges *)
    module Vertex : VERTEX with type t = vertex
    module Edge : EDGE with type t = edge
        and type vertex = vertex
        and type label = edge_label
    module VertexLabel : VERTEXLABEL with type t = vertex_label
    module EdgeLabel : EDGELABEL with type t = edge_label

    (* check if a vertex exists *)
    val mem : t -> vertex -> bool

    (* get in/out edges for a vertex *)
    val in_edges : t -> vertex -> edge list
    val out_edges : t -> vertex -> edge list

    (* get the label for a vertex *)
    val label : t -> vertex -> vertex_label

    (* get all vertices and edges *)
    val vertices : t -> vertex list
    val edges : t -> edge list
end
