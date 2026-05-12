type leaf = Leaf of int

type wrapper = Wrapper of leaf

type unused_leaf = UnusedLeaf of string

type unused_wrapper = UnusedWrapper of unused_leaf

let live_value = Wrapper (Leaf 1)

let dead_value = UnusedWrapper (UnusedLeaf "unused")
