open DataSig

module SQLite : Data = struct
    type t = Sqlite3.db
    type vertex = Identifier.t
    type graph = Document.DocGraph.t
    type query = GraphRule.Query.t

    let of_string filename = Sqlite3.db_open filename

    module DataGraph = Document.DocGraph

    let context db n id = DataGraph.empty

    let negative_instances db n id = []

    let count db q = 0
    let apply db q = []

    let apply_on db q ids = []
end