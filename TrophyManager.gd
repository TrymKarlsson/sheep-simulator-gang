extends Node

signal trophy_collected(count: int)

var collected = 0
var total = 10

func collect():
	collected += 1
	trophy_collected.emit(collected)
