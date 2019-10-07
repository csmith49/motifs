(* steps we can take *)

(* 1 - weaken a vertex label *)
(* there are two ways to weaken - we can remove, or we can replace, so *)
(* 1.a - remove a vertex label *)
(* 1.b - replace label with logically weaker label *)

(* 2 - remove a vertex *)
(* when a vertex is removed, make sure that unecessary edges are trimmed *)

(* 3 - remove an edge *)
(* when an edge is removed, the graph may become disconnected - don't remove in that case *)

(* goals of inference *)
(* 1 - break as many symmetries as possible *)
(* 2 - maintain soundness *)
(* 3 - incorporate semantics eventually *)

open Rule
type rule = GraphRule.t
module G = GraphRule.RuleGraph
let lift = GraphRule.map

let graph rule = rule.GraphRule.graph

(* PREDICATE WEAKENING *)

(* a *)
let drop_predicate vertex rule : rule = lift (fun g -> G.remove_label g vertex) rule

(* b *)
let project_conjunction vertex rule : rule list =
    let conjunction = G.label (graph rule) vertex 
        |> CCOpt.map Predicate.clauses
        |> CCOpt.get_or ~default:[] in
    CCList.map (fun conjunct ->
        let pred = Predicate.singleton conjunct in 
        lift (fun g -> G.add_label g vertex pred) rule
    ) conjunction

(* c *)
let weaken_predicate vertex rule : rule list =
    let conjunction = G.label (graph rule) vertex 
        |> CCOpt.map Predicate.clauses
        |> CCOpt.get_or ~default:[] in
    match conjunction with
        | [pred] ->
            let weakenings = Predicate.Clause.weaken pred in
            CCList.map (fun weakening ->
                let pred = Predicate.singleton weakening in
                lift (fun g -> G.add_label g vertex pred) rule) weakenings
        | _ -> []

(* REMOVE VERTEX *)

let remove_vertex vertex rule : rule = lift (fun g -> G.remove_vertex g vertex) rule

(* REMOVE EDGE *)

let remove_edge edge rule : rule = lift (fun g -> G.remove_edge Core.Value.equal g edge) rule

(* SUMMARIZE *)
let weaken_at_vertex vertex rule =
    let removed = remove_vertex vertex rule in
    let base = (drop_predicate vertex rule) :: (project_conjunction vertex rule) in
    let weakened = CCList.flat_map (weaken_predicate vertex) base in
        removed :: base @ weakened

let weaken_at_edge edge rule =
    [rule ; remove_edge edge rule]