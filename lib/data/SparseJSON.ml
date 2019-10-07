open Signatures
open Core
open Rule

module SQLMake (I : SQLData) = struct
    type t = Yojson.Basic.t

    let rule_image (db : I.t) (rule : GraphRule.t) : t =
        let query = SQLQuery.of_rule rule in
        let selected = I.apply db query in
        `Assoc [
            ("sign", `Bool true);
            ("image", `List (selected |> CCList.map Identifier.to_json))
        ]

    let ensemble_image (db : I.t) (rules : GraphRule.t list) : t =
        let images = CCList.mapi (fun i -> fun rule -> 
            (string_of_int i, rule_image db rule)
        ) rules in
        `Assoc images

    let index_to_file (filename : string) (rules : GraphRule.t list) =
        let index = CCList.mapi (fun i -> fun rule ->
            (string_of_int i, GraphRule.to_json rule)
        ) rules in Yojson.Basic.to_file filename (`Assoc index)

    let to_file (filename : string) (img : t) : unit = Yojson.Basic.to_file filename img
end