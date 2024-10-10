class_name SetsuNodeDefintion
extends Resource

@export var name := "NodeName"
@export var icon: Texture

## Styles
@export_group("Styles", "style_")
@export var style_normal: StyleBox
@export_group("Styles", "style_")
@export var style_selected: StyleBox

## Nodes
@export_group("Nodes", "node_")
@export var node_graph: PackedScene
@export_group("Nodes", "node_")
@export var node_inspector: PackedScene
