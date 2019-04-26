module R = Rule.GraphRule.RuleGraph

type rule = Rule.GraphRule.t

(* lower is better! *)
let score rule =
    let graph = rule.Rule.GraphRule.graph in
    (* let num_vertices = graph
        |> R.vertices
        |> CCList.length in *)
    let num_labeled_vertices = graph
        |> R.vertices
        |> CCList.filter_map (R.label graph)
        |> CCList.length in
    (* let num_unlabeled_vertices = num_vertices - num_labeled_vertices in *)
    let num_edges = graph
        |> R.edges
        |> CCList.length in
    let max_degree = graph
        |> R.vertices
        |> CCList.map (R.degree graph)
        |> CCList.fold_left CCInt.max 0 in
    num_labeled_vertices + num_edges + max_degree