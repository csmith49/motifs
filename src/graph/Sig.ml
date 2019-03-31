(* vertices need to be able to be stored and manipulated easily *)
module type Vertex = sig
    type t
    include CCBijection.OrderedType with type t := t
end

(* labels only have the requirement that they exist *)
module type VertexLabel = sig
    type t
end

module type EdgeLabel = sig
    type t
end

(* edges optionally carry labels *)
module type Edge = sig
    type t
    type vertex
    type label

    val make : vertex -> vertex -> t
    val make_labeled : vertex -> label -> vertex -> t
    val source : t -> vertex
    val destination : t -> vertex
    val label : t -> label option
end

module type SemanticGraph = sig
    type t
    type vertex_label
    type edge_label
    type vertex
    type edge

    module Vertex : Vertex with
        type t = vertex
    module Edge : Edge with
        type t = edge
        and type vertex = vertex
        and type label = edge_label
    
    module VertexLabel : VertexLabel with
        type t = vertex_label
    module EdgeLabel : EdgeLabel with
        type t = edge_label

    val empty : t

    val mem : t -> vertex -> bool

    val in_edges : t -> vertex -> edge list
    val out_edges : t -> vertex -> edge list

    val label : t -> vertex -> vertex_label option

    val add_vertex : t -> vertex -> t
    val add_labeled_vertex : t -> vertex -> vertex_label -> t

    val add_edge : t -> edge -> t

    val vertices : t -> vertex list

    val edges : t -> edge list
end

module type Isomorphism = sig
    type t

    type domain
    type codomain

    val empty : t
    val add : t -> domain -> codomain -> t
    val image : t -> domain -> codomain option
    val domain : t -> domain list
    val codomain : t -> codomain list
end

module type Embedding = sig
    module Domain : SemanticGraph
    module Codomain : SemanticGraph

    module Isomorphism : Isomorphism with
        type domain = Domain.vertex
        and type codomain = Codomain.vertex

    val check_vertex : Domain.vertex_label option -> Codomain.vertex_label option -> bool
    val check_edge : Domain.edge_label option -> Codomain.edge_label option -> bool
end