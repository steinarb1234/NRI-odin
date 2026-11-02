package main

import "core:sys/windows"
import "core:sync"
import     "core:os"
import     "core:fmt"
import     "core:log"
import     "base:runtime"
import sdl "vendor:sdl3"
import nri "../../"



sdl_log :: proc "c" (userdata: rawptr, category: sdl.LogCategory, priority: sdl.LogPriority, message: cstring) {
	context = (transmute(^runtime.Context)userdata)^
	level: log.Level
	switch priority {
		case .INVALID, .TRACE, .VERBOSE, .DEBUG: level = .Debug
		case .INFO: level = .Info
		case .WARN: level = .Warning
		case .ERROR: level = .Error
		case .CRITICAL: level = .Fatal
	}
	log.logf(level, "SDL {}: {}", category, message)
}

sdl_assert :: proc(ok: bool) {
	if !ok do log.panicf("SDL Error: %s", sdl.GetError())
}

// NRI can invoke message callbacks from multiple threads
@(private = "file")
debug_output_mutex : sync.Mutex

debug_message_callback :: proc "c" (
	message_type: nri.Message,
	file        : cstring,
	line        : u32,
	message     : cstring,
	user_arg    : rawptr,
) {
	// Foreign callbacks do not inherit the callers Odin context
	context = runtime.default_context()

	level_name := "UNKNOWN"
	switch message_type {
		case .INFO:
			level_name = "INFO"
		case .WARNING:
			level_name = "WARNING"
		case .ERROR:
			level_name = "ERROR"
		case .MAX_NUM:
			level_name = "MAX_NUM"
	}

	sync.mutex_lock(&debug_output_mutex)
	defer sync.mutex_unlock(&debug_output_mutex)

	fmt.eprintfln("[NRI %s] %s:%d - %s", level_name, file, line, message)

	if message != nil {
		windows.OutputDebugStringA(message)
		windows.OutputDebugStringA("\n")
	}
}

// debug_no_abort_callback delibaretly does nothing. Supplying a non-nil 
// callback prevents NRI from using its default Debugbreak callback.
debug_no_abort_callback :: proc "c" (user_arg: rawptr) {
}

debug_break_callback :: proc "c" (user_arg: rawptr) {
	runtime.debug_trap()
}

make_debug_callback_interface :: proc(
	break_on_error := false,
	user_arg: rawptr = nil,
) -> nri.CallbackInterface {
	if break_on_error {
		return nri.CallbackInterface{
			MessageCallback = debug_message_callback,
			AbortExecution  = debug_break_callback,
			userArg         = user_arg,
		}
	}

	return nri.CallbackInterface{
		MessageCallback = debug_message_callback,
		AbortExecution  = debug_break_callback,
		userArg         = user_arg
	}
}

NRI_ABORT_ON_FAILURE :: proc(
    result: nri.Result, 
    operation: string,
    location := #caller_location,
) {
    if result != .SUCCESS {
        sync.mutex_lock(&debug_output_mutex)
        fmt.eprintfln("NRI failure: %s returned %v at %s:%d", operation, result, location.file_path, location.line)
		sync.mutex_unlock(&debug_output_mutex)  
	}
}

// nri_message_callback :: proc "c" (
// 	level: nri.Message,
//     file: cstring,
//     line: u32,
//     message: cstring,
//     user_data: rawptr,
// ) {
//     level_name := "INFO"
//     switch level {
// 		case .INFO:    level_name = "INFO"
// 		case .WARNING: level_name = "WARN"
// 		case .ERROR:   level_name = "ERROR"
// 		case .MAX_NUM: level_name = "MAX_NUM"
//     }
// 	context = runtime.default_context()
//     fmt.printfln("[NRI %s] %s:%d - %s", level_name, file, line, message)
// }

// nri_abort_callback :: proc "c"(user_data: rawptr) {
// 	context = runtime.default_context()
//     fmt.eprintfln("[NRI] AbortExecution called. Exiting.")
//     nri.DestroyDevice(device)

//     os.exit(-1)
// }
