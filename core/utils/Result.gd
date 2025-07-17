# core/utils/Result.gd
class_name Result
extends RefCounted

var _is_ok: bool = false
var _value = null
var _error: String = ""
var _error_code: int = 0

func _init():
	pass

# State checkers
func is_ok() -> bool:
	return _is_ok

func is_err() -> bool:
	return not _is_ok

# Value extraction
func unwrap():
	if _is_ok:
		return _value
	else:
		push_error("Attempted to unwrap error result: %s" % _error)
		return null

func get_error() -> String:
	return _error

func get_error_code() -> int:
	return _error_code

# Static factory methods
static func ok(value = null) -> Result:
	var result = Result.new()
	result._is_ok = true
	result._value = value
	return result

static func err(error_msg: String, error_code: int = -1) -> Result:
	var result = Result.new()
	result._is_ok = false
	result._error = error_msg
	result._error_code = error_code
	return result

# Error codes enum
enum ErrorCode {
	NONE = 0,
	INVALID_INPUT = 1,
	NETWORK_ERROR = 2,
	PERMISSION_DENIED = 3,
	NOT_FOUND = 4,
	ALREADY_EXISTS = 5,
	RESOURCE_EXHAUSTED = 6,
	INVALID_STATE = 7,
	OPERATION_FAILED = 8,
	IO_ERROR = 9,
	DATA_LOSS = 10,
	INTERNAL = 11,
	OUT_OF_RANGE = 12,
}
