type t =
    | Top
    | Conjunct of Predicate.t * t

let rec of_list = function
    | [] -> Top
    | x :: rest -> Conjunct (x, of_list rest)
let rec to_list = function
    | Top -> []
    | Conjunct (pred, rest) -> pred :: (to_list rest)

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