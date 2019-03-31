open Sig

module Iso (D : SemanticGraph) (C : SemanticGraph) : Isomorphism 
    with type domain = D.vertex and type codomain = C.vertex
= struct
    type domain = D.vertex
    type codomain = C.vertex

    module Bijection = CCBijection.Make(D.Vertex)(C.Vertex)

    type t = Bijection.t

    let empty = Bijection.empty

    let add b d c = Bijection.add d c b

    let image b d = if Bijection.mem_left d b then Some (Bijection.find_left d b) else None
    
    let domain b = Bijection.to_list b |> CCList.map fst

    let codomain b = Bijection.to_list b |> CCList.map snd
end