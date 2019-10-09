type t =
    | Star
    | Constant of Core.Value.t

let of_value v = Constant v

let apply kinder value = match kinder with
    | Star -> true
    | Constant c -> Core.Value.equal c value

let to_json = function
    | Star -> `Assoc [("kind", `String "*")]
    | Constant c -> `Assoc [
        ("kind", `String "constant");
        ("constant", Core.Value.to_json c)
    ]

let of_json json = match Utility.JSON.get "kind" Utility.JSON.string json with
    | Some s when s = "*" -> Some Star
    | Some s when s = "constant" -> begin match Utility.JSON.get "constant" Core.Value.of_json json with
        | Some c -> Some (Constant c)
        | None -> None end
    | _ -> None