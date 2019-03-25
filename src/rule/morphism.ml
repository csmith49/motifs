module Bijection = CCBijection.Make(Identifier)(Identifier)

type t = Bijection.t
type binding = Identifier.t * Identifier.t

(* exposing the functions we care about *)

(* constructions *)
let empty : t = Bijection.empty

let of_list : binding list -> t = Bijection.of_list

(* insertions *)
let add : Identifier.t -> Identifier.t -> t -> t = Bijection.add
let add_binding : binding -> t -> t = fun (l, r) -> fun m -> add l r m

let find_left : Identifier.t -> t -> Identifier.t = Bijection.find_left
let find_right : Identifier.t -> t -> Identifier.t = Bijection.find_right

(* testing for inclusion *)
let mem_left : Identifier.t -> t -> bool = Bijection.mem_left

(* transformations *)
let to_list : t -> binding list = Bijection.to_list
let to_list_left : t -> Identifier.t list = fun ls -> to_list ls |> CCList.map fst