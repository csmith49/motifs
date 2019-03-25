(* filters map values into the bools *)

type t = {
    name : string;
    implementation : Value.t -> bool;
}

(* so we don't have to unpack *)
let apply : t -> Value.t -> bool = fun f -> fun v -> f.implementation v

(* basic printing *)
let to_string : t -> string = fun f -> f.name

(* assume names uniquely represent any impl *)
let compare : t -> t -> int = fun l -> fun r ->
    CCString.compare l.name r.name

(* utilities for constructing filters *)
module Make = struct
    (* check for equality with a value *)
    let of_value : Value.t -> t = fun value -> {
        name = Value.to_string value;
        implementation = fun v -> Value.equal value v;
    }

    (* from of_value, cast primitives to a value first *)
    let of_int : int -> t = fun i -> of_value (Value.of_int i)
    let of_string : string -> t = fun s -> of_value (Value.of_string s)
    let of_bool : bool -> t = fun b -> of_value (Value.of_bool b)

    (* top and bottom on the lattice *)
    let top = { name = "TOP"; implementation = fun _ -> true; }
    let bottom = { name = "BOT"; implementation = fun _ -> false; }
end

(* just in case *)
let default = Make.top