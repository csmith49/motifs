module Consistency (DB : Signatures.SQLData) : (sig
    type db
    val consistent_with : db -> SQLQuery.t -> Core.Identifier.t list -> Core.Identifier.t list -> bool
end with type db := DB.t) = struct
    let consistent_with db q pos neg =
        let dom = pos @ neg in
        let img = DB.apply_on db q dom in
            CCList.for_all (fun p -> CCList.mem ~eq:Core.Identifier.equal p img) pos &&
            not (CCList.exists (fun n -> CCList.mem ~eq:Core.Identifier.equal n img) neg)
end