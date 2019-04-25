let id = Core.Identifier.of_int 0

module type Test = Graph.Signatures.SemanticGraph

module Doc = Domain.Document

module Rule = Rule.GraphRule

module S = Synthesis