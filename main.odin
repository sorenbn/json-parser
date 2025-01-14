/*
==========================================
A very basic JSON parser in Odin, based on the following article:
https://ogzhanolguncu.com/blog/write-your-own-json-parser/
==========================================
*/

package main

import "core:fmt"
import "core:mem"
import "core:os"
import str "core:strings"
import json "jsonparser"

main :: proc() {
	track_alloc: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track_alloc, context.allocator)
	context.allocator = mem.tracking_allocator(&track_alloc)
	defer {
		fmt.eprintf("\n")
		for _, entry in track_alloc.allocation_map {
			fmt.eprintf("- %v leaked %v bytes\n", entry.location, entry.size)
		}
		for entry in track_alloc.bad_free_array {
			fmt.eprintf("- %v bad free\n", entry.location)
		}
		mem.tracking_allocator_destroy(&track_alloc)
		fmt.eprintf("\n")

		free_all(context.temp_allocator)
	}

	json_string, success := read_file_as_string("assets/file.json")
	if !success {
		fmt.println("Error reading file.")
		return
	}
	defer delete(json_string)

	tokens := json.tokenize(&json_string)
	defer json.delete_tokens(tokens[:])

	for token in tokens do fmt.println(token)

	node_tree, _ := json.parse_tokens(tokens[:])
	defer json.delete_node_recursive(node_tree)

	fmt.println(node_tree)
}

/*
Read a file at path and converts it to a string.
*/
read_file_as_string :: proc(filepath: string) -> (data: string, success: bool) {
	bytes, ok := os.read_entire_file(filepath)
	defer delete(bytes)
	if !ok {
		return "", false
	}

	return str.clone(string(bytes)), true
}
