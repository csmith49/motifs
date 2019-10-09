include Utility.Graph.GRAPH with type vertex := Identifier.t

val of_json : 
    (Yojson.Basic.t -> 'v option) -> 
    (Yojson.Basic.t -> 'e option) -> 
        Yojson.Basic.t -> ('v, 'e) t option
val to_json :
    ('v -> Yojson.Basic.t) ->
    ('e -> Yojson.Basic.t) ->
        ('v, 'e) t -> Yojson.Basic.t