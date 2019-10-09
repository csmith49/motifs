type t = [
    | `Constant of string * Core.Value.t
]

let of_pair (key, value) = `Constant (key, value)

let apply pred map = match pred with
    | `Constant (key, value) ->
        match Core.Value.Map.get key map with
            | Some v -> Core.Value.equal v value
            | None -> false

let to_json = function
    | `Constant (attr, value) -> `Assoc [
        ("kind", `String "constant");
        ("attribute", `String attr);
        ("value", Core.Value.to_json value)]

let of_json json = match Utility.JSON.get "kind" Utility.JSON.string json with
    | Some s when s = "constant" ->
        let attr = Utility.JSON.get "attribute" Utility.JSON.string json in
        let value = Utility.JSON.get "value" Core.Value.of_json json in
        begin match attr, value with
            | Some attr, Some value -> Some (`Constant (attr, value))
            | _ -> None end
    | _ -> None