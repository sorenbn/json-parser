package jsonparser

import "core:fmt"
import "core:strconv"
import str "core:strings"
import rx "core:text/regex"
import rxcommon "core:text/regex/common"

TokenType :: enum {
	BRACE_OPEN,
	BRACE_CLOSE,
	BRACKET_OPEN,
	BRACKET_CLOSE,
	STRING,
	NUMBER,
	COMMA,
	COLON,
	TRUE,
	FALSE,
	NULL,
}

Token :: struct {
	type:  TokenType,
	value: string,
}

/*
Generates an array of tokens from the given input.
Input is expected to be json formatted.
*/
tokenize :: proc(input: ^string) -> [dynamic]Token {
	tokens: [dynamic]Token
	iterator := 0

	number_bool_null_regex, _ := rx.create("[\\d\\w]", {rxcommon.Flag.Global})
	defer rx.destroy(number_bool_null_regex)

	whitespace_regex, _ := rx.create("[\\s]", {rxcommon.Flag.Global})
	defer rx.destroy(whitespace_regex)

	for iterator < len(input) {
		character := input[iterator]

		if character == '{' {
			append(&tokens, Token{type = .BRACE_OPEN, value = input[iterator:iterator + 1]})
			iterator += 1
			continue
		}

		if (character == '}') {
			append(&tokens, Token{type = .BRACE_CLOSE, value = input[iterator:iterator + 1]})
			iterator += 1
			continue
		}

		if (character == '[') {
			append(&tokens, Token{type = .BRACKET_OPEN, value = input[iterator:iterator + 1]})
			iterator += 1
			continue
		}

		if (character == ']') {
			append(&tokens, Token{type = .BRACKET_CLOSE, value = input[iterator:iterator + 1]})
			iterator += 1
			continue
		}

		if (character == ':') {
			append(&tokens, Token{type = .COLON, value = input[iterator:iterator + 1]})
			iterator += 1
			continue
		}

		if (character == ',') {
			append(&tokens, Token{type = .COMMA, value = input[iterator:iterator + 1]})
			iterator += 1
			continue
		}

		// strings
		if character == '\"' {
			builder := str.builder_make(context.temp_allocator)
			defer str.builder_destroy(&builder)

			iterator += 1
			next_character := input[iterator]

			for next_character != '\"' {
				str.write_string(&builder, input[iterator:iterator + 1])
				iterator += 1
				next_character = input[iterator]
			}

			iterator += 1
			append(&tokens, Token{type = .STRING, value = str.to_string(builder)})
			continue
		}

		// bool, number or null check.
		capture, found_match := rx.match_and_allocate_capture(
			number_bool_null_regex,
			input[iterator:iterator + 1],
		)
		defer rx.destroy_capture(capture)

		if found_match {
			builder := str.builder_make(context.temp_allocator)
			defer str.builder_destroy(&builder)

			for found_match {
				str.write_string(&builder, input[iterator:iterator + 1])
				iterator += 1
				capture, next_found := rx.match_and_allocate_capture(
					number_bool_null_regex,
					input[iterator:iterator + 1],
				)
				defer rx.destroy_capture(capture)

				found_match = next_found
			}

			final_string := str.to_lower(str.to_string(builder))
			defer delete(final_string)

			if final_string == "null" {
				append(&tokens, Token{type = .NULL, value = final_string})
			} else if _, ok := strconv.parse_int(final_string); ok {
				append(&tokens, Token{type = .NUMBER, value = final_string})
			} else if bool_val, ok := strconv.parse_bool(final_string); ok {
				append(
					&tokens,
					Token{type = bool_val ? .TRUE : .FALSE, value = bool_val ? "true" : "false"},
				)
			}

			iterator += 1
			continue
		}

		// skip whitespace
		ws_capture, found_match_whitespace := rx.match_and_allocate_capture(
			whitespace_regex,
			input[iterator:iterator + 1],
		)
		defer rx.destroy_capture(ws_capture)

		if found_match_whitespace {
			iterator += 1
			continue
		}

		fmt.println(fmt.tprint("ERROR: Unknown character: ", character))
		break
	}

	return tokens
}

/*
Cleanup tokens
*/
delete_tokens :: proc(tokens: []Token) {
	delete(tokens)
}
