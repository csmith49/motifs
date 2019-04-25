type t = [
    | `Int of int
    | `String of string
    | `Bool of bool
    | `Null
]
type value = t

(* conversions from ocaml literals *)
let of_int_lit : int -> t = fun i -> `Int i
let of_string_lit : string -> t = fun s -> `String s
let of_bool_lit : bool -> t = fun b -> `Bool b

let of_string : string -> t = fun s ->
    match int_of_string_opt s with
        | Some i -> `Int i
        | None -> match bool_of_string_opt s with
            | Some b -> `Bool b
            | None -> `String s

(* and to ocaml literals *)
let to_int_opt : t -> int option = function
    | `Int i -> Some i
    | _ -> None
let to_string_opt : t -> string option = function
    | `String s -> Some s
    | _ -> None
let to_bool_opt : t -> bool option = function
    | `Bool b -> Some b
    | _ -> None

(* for printing *)
let to_string : t -> string = function
    | `Int i -> string_of_int i
    | `String s -> "'" ^ s ^ "'"
    | `Bool b -> (string_of_bool b)
    | `Null -> "NULL"

(* picking out particular constructors *)
let is_null : t -> bool = function
    | `Null -> true
    | _ -> false

(* comparisons don't really mean much with such a heterogeneous type *)
let compare = Pervasives.compare
let equal = (=)

(* converting from json representations *)
let of_json : JSON.t -> t option = function
    | `Int i -> Some (`Int i)
    | `String s -> Some (`String s)
    | `Bool b -> Some (`Bool b)
    | `Null -> Some (`Null)
    | _ -> None
let to_json : t -> JSON.t = function
    | `Int i -> `Int i
    | `String s -> `String s
    | `Bool b -> `Bool b
    | `Null -> `Null

(* indexing values by strings *)
module Map = struct
    (* we're always going to index by strings here *)
    module StringMap = CCMap.Make(CCString)
    
    (* concretize the type more *)
    type t = value StringMap.t

    (* expose some simple functions *)
    let empty : t = StringMap.empty
    let get : CCString.t -> t -> value option = StringMap.get
    let add : CCString.t -> value -> t -> t = StringMap.add
    let to_list : t -> (CCString.t * value) list = StringMap.bindings

    let is_empty : t -> bool = StringMap.is_empty

    let keys : t -> string list = fun m -> StringMap.to_list m |> CCList.map fst
    let values : t -> value list = fun m -> StringMap.to_list m |> CCList.map snd


    let to_json : t -> JSON.t = fun m -> 
        let ls = m 
            |> StringMap.to_list
            |> CCList.map (fun (k, v) -> (k, to_json v)) in
        `Assoc ls
    (* the getter from json *)
    let of_json : JSON.t -> t option = function
        | `Assoc attrs ->
            let binding_of_json (k, v) = match of_json v with
                | Some v -> Some (k, v)
                | _ -> None
            in CCList.map binding_of_json attrs
                |> CCOpt.sequence_l
                |> CCOpt.map StringMap.of_list
        | _ -> None

    (* string conversion *)
    let to_string : t -> string = fun map ->
        let map = map |> to_list
            |> CCList.map (fun (k, v) -> k ^ " : " ^ (to_string v))
            |> CCString.concat ", "
        in "[" ^ map ^ "]"
end