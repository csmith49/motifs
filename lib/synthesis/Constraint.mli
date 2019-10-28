type checker = Delta.t -> Delta.t option

val keep_selector : checker
val drop_dangling_edges : checker
val stay_connected : checker
val attribute_per_node : checker