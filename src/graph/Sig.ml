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
    val add_label : t -> vertex -> vertex_label -> t
    val remove_label : t -> vertex -> t
    val remove_vertex : t -> vertex -> t

    val add_edge : t -> edge -> t
    val remove_edge : (edge -> edge -> bool) -> t -> edge -> t
    val remove_edge_label : (edge -> edge -> bool) -> t -> edge -> t

    val vertices : t -> vertex list

    val edges : t -> edge list

    val degree : t -> vertex -> int
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

module type Neighborhood = sig
    type t
    type vertex
    type edge
    type graph

    val mem : t -> vertex -> bool
    val to_list : t -> vertex list

    val starts_in : t -> edge -> bool
    val ends_in : t -> edge -> bool
    val mem_edge : t -> edge -> bool

    val one_hop : vertex -> graph -> t
    val n_hop : int -> vertex -> graph -> t

    val n_hop_subgraph : int -> vertex -> graph -> graph
end

module type Functor = sig
    module Domain : SemanticGraph
    module Codomain : SemanticGraph

    val map_vertex : Domain.vertex -> Codomain.vertex
    val map_vertex_label : Domain.vertex_label option -> Codomain.vertex_label option
    val map_edge_label : Domain.edge_label option -> Codomain.edge_label option
end