type t =
    | Top
    | Conjunct of Predicate.t * t

let rec of_list = function
    | [] -> Top
    | x :: rest -> Conjunct (x, of_list rest)
let rec to_list = function
    | Top -> []
    | Conjunct (pred, rest) -> pred :: (to_list rest)

let compare left right =
    let left' = left
        |> to_list
        |> CCList.sort Predicate.compare in
    let right' = right
        |> to_list
        |> CCList.sort Predicate.compare in
    CCList.compare Predicate.compare left' right'
let equal left right =
    let left' = left
        |> to_list
        |> CCList.sort Predicate.compare in
    let right' = right
        |> to_list
        |> CCList.sort Predicate.compare in
    CCList.equal Predicate.equal left' right'

let implies left right =
    let left' = to_list left in right |> to_list
        |> CCList.for_all (fun r -> CCList.exists (fun l -> Predicate.implies l r) left')
let (=>) left right = implies left right

module Lattice = struct
    let weaken = function
        | Top -> []
        | _ as conjunct -> conjunct |> to_list
            |> CCList.map Predicate.Lattice.weaken
            |> CCList.cartesian_product
            |> CCList.map of_list
end

let of_map map = map
    |> Core.Value.Map.to_list
    |> CCList.map Predicate.of_pair
    |> of_list

let to_json filter = `List (filter
    |> to_list
    |> CCList.map Predicate.to_json)

let of_json json = match Utility.JSON.list Predicate.of_json json with
    | Some ls -> Some (of_list ls)
    | None -> None

let apply filter map = filter
    |> to_list
    |> CCList.for_all (fun p -> Predicate.apply p map)