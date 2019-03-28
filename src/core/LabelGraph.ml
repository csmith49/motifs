module type VertexSignature = CCMap.OrderedType

module type LabelGraphSignature = sig
    type vertex

    type ('a, 'b) t

    module Edge : sig
        type 'a t

        val source : 'a t -> vertex
        val destination : 'a t -> vertex
        val label : 'a t -> 'a option

        val make : vertex -> vertex -> 'a t
        val make_labeled : vertex -> 'a -> vertex -> 'a t
    end

    val empty : ('a, 'b) t

    val mem : ('a, 'b) t -> vertex -> bool

    val add_vertex : ('a, 'b) t -> vertex -> ('a, 'b) t
    val add_label : ('a, 'b) t -> vertex -> 'a -> ('a, 'b) t option
    val add_labeled_vertex : ('a, 'b) t -> vertex -> 'a -> ('a, 'b) t

    val add_edge : ('a, 'b) t -> 'b Edge.t -> ('a, 'b) t

    val in_edges : ('a, 'b) t -> vertex -> 'b Edge.t list
    val out_edges : ('a, 'b) t -> vertex -> 'b Edge.t list
    val label : ('a, 'b) t -> vertex -> 'a option
end

module Make (V : VertexSignature) : LabelGraphSignature = struct
    type vertex = V.t
    module VertexMap = CCMap.Make(V)

    module Edge = struct
        type 'a t = E of vertex * 'a option * vertex

        let source = function E (src, _, _) -> src
        let destination = function E (_, _, dest) -> dest
        let label = function E (_, lbl, _) -> lbl

        let make src dest = E (src, None, dest)
        let make_labeled src lbl dest = E (src, Some lbl, dest)
    end
    
    type ('a, 'b) context = {
        label : 'a option;
        in_edges : 'b Edge.t list;
        out_edges : 'b Edge.t list;
    }

    type ('a, 'b) t = ('a, 'b) context VertexMap.t

    let empty = VertexMap.empty

    let mem graph vertex = VertexMap.mem vertex graph

    let add_vertex graph vertex = VertexMap.add vertex {label = None; in_edges = []; out_edges = []} graph
    let add_label graph vertex label =
        match VertexMap.find_opt vertex graph with
            | Some context ->
                let context = {context with label = Some label} in
                Some (VertexMap.add vertex context graph)
            | None -> None
    let add_labeled_vertex graph vertex label =
        VertexMap.add vertex {label = Some label; in_edges = []; out_edges = []} graph
     
    let add_edge graph edge =
        let src, dest = Edge.source edge, Edge.destination edge in
        let src_c = match VertexMap.find_opt src graph with
            | Some context -> context
            | None -> {label = None; in_edges = []; out_edges = []}
        in let dest_c = match VertexMap.find_opt dest graph with
            | Some context -> context
            | None -> {label = None; in_edges = []; out_edges = []}
        in graph
            |> VertexMap.add src {src_c with out_edges = edge :: src_c.out_edges}
            |> VertexMap.add dest {dest_c with in_edges = edge :: dest_c.in_edges}
    
    let in_edges graph vertex = match VertexMap.find_opt vertex graph with
        | Some c -> c.in_edges
        | _ -> []
    let out_edges graph vertex = match VertexMap.find_opt vertex graph with
        | Some c -> c.out_edges
        | _ -> []
    let label graph vertex = match VertexMap.find_opt vertex graph with
        | Some c -> c.label
        | _ -> None
end