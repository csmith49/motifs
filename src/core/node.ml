(* use strings to index attributes *)
module StringMap = CCMap.Make(CCString)

(* mostly, nodes just keep an id and a set of attributes around *)
type t = {
    id : int;
    attributes : Value.t StringMap.t;
}

(* printing *)
let to_string : t -> string = fun n ->
    let id = string_of_int n.id in
    let binding_to_string (k, v) =
        k ^ " : " ^ (Value.to_string v) in
    let attrs = n.attributes
        |> StringMap.bindings
        |> CCList.map binding_to_string
        |> CCString.concat ", " in
    id ^ "[" ^ attrs ^ "]"

(* conversion from json *)
let bindings_of_json : Yojson.Basic.t -> Value.t StringMap.t option = function
    | `Assoc xs ->
        let binding_of_json (k, v) = match Value.of_json v with
            | Some v -> Some (k, v)
            | _ -> None in
        xs 
            |> CCList.map binding_of_json
            |> CCOpt.sequence_l
            |> CCOpt.map StringMap.of_list
    | _ -> None

let of_json : Yojson.Basic.t -> t option = function
    | `Assoc xs ->
        let id = xs
            |> CCList.assoc_opt ~eq:(=) "id"
            |> CCOpt.flat_map Value.of_json
            |> CCOpt.flat_map Value.to_int_opt in
        let attributes = xs
            |> CCList.assoc_opt ~eq:(=) "attributes"
            |> CCOpt.flat_map bindings_of_json in
        CCOpt.map2 (fun id -> fun attrs -> {id = id; attributes = attrs}) id attributes
    | _ -> None