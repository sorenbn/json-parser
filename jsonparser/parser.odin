package jsonparser

import "core:strconv"

Node :: union {
	ObjectNode,
	ArrayNode,
	StringNode,
	NumberNode,
	BooleanNode,
	NullNode,
}

ObjectNode :: struct {
	value: map[string]Node,
}
ArrayNode :: struct {
	value: [dynamic]Node,
}
StringNode :: struct {
	value: string,
}
NumberNode :: struct {
	value: f32,
}
BooleanNode :: struct {
	value: bool,
}
NullNode :: struct {}

/*
Input tokens from the tokenizer to convert them into a node graph.
*/
parse_tokens :: proc(tokens: []Token) -> (Node, bool) {
	if len(tokens) == 0 {
		return nil, false
	}

	iterator := 0
	node, success := parse_token(tokens, &iterator)

	return node, success
}

/*
Converts a token into their respective node. Iterator is the current index it's at.
Will be called recursively.
*/
parse_token :: proc(tokens: []Token, iterator: ^int) -> (Node, bool) {
	current_token := tokens[iterator^]

	#partial switch current_token.type {
	case .STRING:
		return StringNode{value = current_token.value}, true
	case .NUMBER:
		return NumberNode{value = f32(strconv.atof(current_token.value))}, true
	case .TRUE:
		return BooleanNode{value = true}, true
	case .FALSE:
		return BooleanNode{value = false}, true
	case .NULL:
		return NullNode{}, true
	case .BRACE_OPEN:
		return parse_object(tokens, iterator)
	case .BRACKET_OPEN:
		return parse_array(tokens, iterator)
	}

	return nil, false
}

/*
Convert a json-object token into an ObjectNode.
*/
parse_object :: proc(tokens: []Token, iterator: ^int) -> (ObjectNode, bool) {
	node: ObjectNode
	iterator^ += 1

	for tokens[iterator^].type != .BRACE_CLOSE {
		if tokens[iterator^].type != .STRING do return {}, false

		key := tokens[iterator^].value

		iterator^ += 1

		if tokens[iterator^].type != .COLON do return {}, false

		iterator^ += 1
		value, _ := parse_token(tokens, iterator)
		node.value[key] = value

		iterator^ += 1

		if tokens[iterator^].type == .COMMA do iterator^ += 1
	}

	return node, true
}

/*
Convert a json-array token into an ArrayNode.
*/
parse_array :: proc(tokens: []Token, iterator: ^int) -> (ArrayNode, bool) {
	node := ArrayNode {
		value = make([dynamic]Node),
	}

	iterator^ += 1

	for tokens[iterator^].type != .BRACKET_CLOSE {
		value, _ := parse_object(tokens, iterator)
		append(&node.value, value)

		iterator^ += 1

		if tokens[iterator^].type == .COMMA do iterator^ += 1
	}

	return node, true
}

/*
Deletes a node recursively, traversing all child nodes and cleans up memory.
*/
delete_node_recursive :: proc(node: Node) {
	if object_node, is_object := node.(ObjectNode); is_object {
		for key, value in object_node.value do delete_node_recursive(value)
		delete(object_node.value)
	} else if array_node, is_array := node.(ArrayNode); is_array {
		for x in array_node.value do delete_node_recursive(x)
		delete(array_node.value)
	}
}
