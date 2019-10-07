module DBCache (D : Signatures.SQLData)  = struct
    module Data = D
    
    type key = string
    
    let key id = id

    module StringMap = CCMap.Make(CCString)

    type t = D.t StringMap.t

    let add cache key filename =
        (* open the file *)
        let db = Data.of_string filename in StringMap.add key db cache

    let get cache key = StringMap.get key cache
end

(* module Union (D : Signatures.SQLData) : (sig include Signatures.SQLData end) = struct
    module Cache = DBCache(D)
    type t = Cache.t
end *)