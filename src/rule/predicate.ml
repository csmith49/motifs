(* predicates are filters applied to particular attributes *)

type t = {
    attribute : string;
    filter : Filter.t;
}

let attribute p = p.attribute
let value p = Filter.to_string p.filter

let mk string filt = {
    attribute = string;
    filter = filt;
}

let to_string : t -> string = fun pred ->
    (Filter.to_string pred.filter) ^ " @ " ^ pred.attribute

let apply : t -> Value.Map.t -> bool = fun pred -> fun attrs -> match
    Value.Map.get pred.attribute attrs with
        | Some value -> Filter.apply pred.filter value
        | _ -> false

(* for conjunctions *)
type predicate = t

module Conjunction = struct
    type t = predicate list

    let to_string : t -> string = fun conj -> conj
        |> CCList.map to_string
        |> CCString.concat " & "

    let apply : t -> Value.Map.t -> bool = fun conj -> fun attrs -> conj
        |> CCList.for_all (fun pred -> apply pred attrs)
    
    let select : t -> int -> t option = fun c -> fun i -> CCList.nth_opt c i |> CCOpt.map CCList.return
end