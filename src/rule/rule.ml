module RNode = Identifier
module REdge = Filter

module RuleGraph = Graph.Persistent.Digraph.ConcreteBidirectionalLabeled(RNode)(REdge)

module NodeMap = CCMap.Make(Identifier)

type t = {
    selected : Identifier.t list;
    graph : RuleGraph.t;
    predicates : Predicate.Conjunction.t NodeMap.t;
}

(* matching structure across rules and documents *)
let convolve_vertex (rule : t) (doc : Document.t) (dom : RuleGraph.V.t) (codom : Document.DocGraph.V.t) : bool =
    let conj = NodeMap.get_or ~default:[] dom rule.predicates in
    let attrs = Document.get_attributes doc codom in
        Predicate.Conjunction.apply conj attrs

let convolve_edge (rule : t) (doc : Document.t) (dom : RuleGraph.E.t) (codom : Document.DocGraph.E.t) : bool =
    let _, filter, _ = dom in let _, value, _ = codom in Filter.apply filter value

(* checking bindings *)
let check_binding (rule : t) (doc : Document.t) (binding : Morphism.binding) : bool = match binding with
    | (dom, codom) -> convolve_vertex rule doc dom codom

(* check vertex in morphism *)
let check_vertex (rule : t) (doc : Document.t) (m : Morphism.t) (vertex : RuleGraph.V.t) : bool =
    let codom = Morphism.find_left vertex m in convolve_vertex rule doc vertex codom

(* check edge in morphism *)
let check_edge (rule : t) (doc : Document.t) (m : Morphism.t) (edge : RuleGraph.E.t) : bool =
    let src, filter, dest = edge in
    let src_codom = Morphism.find_left src m in
    let dest_codom = Morphism.find_left dest m in
    let edges = Document.get_edges doc src_codom dest_codom in
        CCList.exists (fun (_, value, _) -> Filter.apply filter value) edges

(* check morphism *)
let check_morphism (rule : t) (doc : Document.t) (m : Morphism.t) : bool =
    (* step 1 : check if the nodes convolve *)
    if m |> Morphism.to_list |> CCList.for_all (check_binding rule doc) 
    (* step 2: check if there are edges connecting the nodes *)
    then RuleGraph.fold_edges_e (fun edge -> fun acc ->
        acc && (check_edge rule doc m edge)
    ) rule.graph true
    else false

(* check if a morphism binds all nodes in a rule *)
let unbound_vertices (rule : t) (m : Morphism.t) : RuleGraph.V.t list =
    RuleGraph.fold_vertex (fun v -> fun acc ->
        if Morphism.mem_left v m then acc else v :: acc
    ) rule.graph []
let is_sufficient (rule : t) (m : Morphism.t) : bool =
    CCList.is_empty (unbound_vertices rule m)

type rule = t

module NodeConstraintSet = struct
    module IdentifierMap = CCMap.Make(Identifier)
    module IdentifierSet = CCSet.Make(Identifier)

    type t = IdentifierSet.t IdentifierMap.t

    let constrained_nodes : t -> Identifier.t list = fun dis ->
        dis |> IdentifierMap.to_list |> CCList.map fst
    
    let constraints : t -> Identifier.t -> Identifier.t list = fun dis -> fun id ->
        let c = IdentifierMap.get_or ~default:IdentifierSet.empty id dis in
            IdentifierSet.to_list c
    
    let add_constraint : t -> Identifier.t -> Identifier.t -> t = fun dis -> fun dom -> fun codom ->
        let image = IdentifierMap.get_or ~default:IdentifierSet.empty dom dis in
        let constrained_image = IdentifierSet.add codom image in
            IdentifierMap.add dom constrained_image dis

    let candidate_bindings : t -> (Morphism.binding list * t) = fun dis ->
        match IdentifierMap.choose_opt dis with
            | Some (id, image) ->
                let dis = IdentifierMap.remove id dis in
                let bindings : Morphism.binding list = IdentifierSet.to_list image
                    |> CCList.map (fun im -> (id, im)) in
                (bindings, dis)
            | _ -> [], dis
end

type partial_morphism = Morphism.t * NodeConstraintSet.t

