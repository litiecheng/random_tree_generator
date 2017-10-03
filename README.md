# random_tree_generator

![example](random_tree_generator.gif)

A prototype in Godot (GDScript) to randomly generate tree-like structures.
At this stage, the trees are merely skeletons. Leafs should come in the future.
The main feature is that the trees react to a parent node carrying a "get_wind" method.
So it is possible to make them swing according to that wind variable.
In this example, the wind variable is controlled by an "AnimationPlayer" node that loops over several values.

