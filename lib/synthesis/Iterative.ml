(* module State = struct
    module VSet = CCSet.Make(Core.Identifier)
    module ESet = CCSet.Make(Rule.GraphRule.RuleGraph.Edge)

    module R = Rule.GraphRule.RuleGraph
    type t = {
        rule : Rule.GraphRule.t;
        vertex_history : R.vertex list;
        edge_history : R.edge list;
    }

    let leq left right =
        (Heuristic.score left.rule) <= (Heuristic.score right.rule)

    let weaken : t -> t list = fun state -> []
        (* get the first non-modified vertex *)

        (* if all the vertices are modified, get the first non-modified edge *)

        (* if there aren't any, return the empty list *)
        
end *)

module Make (SQL : Data.Signatures.SQLData) = struct
    module Frontier = CCHeap.Make(Heuristic)

    let is_consistent (db : SQL.t) (r : Heuristic.t) (negatives : Core.Identifier.t list) =
        let query = Data.SQLQuery.of_rule r in
        let img = SQL.apply_on db query negatives in
            (CCList.length img) <= 0

    let enmerate (db : SQL.t) (size : int) (ex : Core.Identifier.t) (view : Domain.View.t) =
        (* generate positive context *)
        let context = SQL.context db size ex view in
        (* convert to rule *)
        let base_rule = {
            Rule.GraphRule.selected = ex;
            graph = Enumeration.DocToRule.apply context;
         } in
        (* find negative examples *)
        let negative_examples = SQL.negative_instances db size ex view in
        (* construct worklist *)
        let worklist = ref (Frontier.add Frontier.empty base_rule) in
        (* and the output list *)
        let output = ref [] in
        (* start the iteration *)
        while (not (Frontier.is_empty !worklist)) do
            (* get the best current rule *)
            let wl, rule = Frontier.take_exn !worklist in
            (* check if the rule is consistent *)
            if is_consistent db rule negative_examples then 
                let weakenings = [] in
                begin
                    output := rule :: !output;
                    worklist := Frontier.add_list wl weakenings
                end 
            else
                worklist := wl
        done; 
        (* return the output *)
        !output
end