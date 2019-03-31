# Graph Rules

## Data Representation

Data is represented by graphs! That's what makes this approach compelling. The graphs are directed, and possibly cyclic.

Nodes have an associated map of key-value pairs, which is possibly empty. We use elements of type `Identifier.t` to represent nodes.

Edges carry a possible value label, or nothing at all, so edge labels are of type `Value.t option`.

Separately, we maintain a map from identifiers to `Value.Map.t` attribute maps.

Nodes are identified by elements of `Identifier.t`, and have an associated value map of attributes `Value.Map.t`, which is possibly empty. In short,
```ocaml
type dnode = {id : Identifier.t; attributes : Value.Map.t}
```

Edges contain less information than nodes. If they carry any value at all, they carry a payload of type `Value.t`. So, edge labels are given by
```ocaml
type dedge = Value.t option
```

To use our graph wrapper from `Ocamlgraph`, we have to enforce some properties on