//
//  Log.swift
//  Gestura
//

import Foundation

/// Lightweight debug logging that compiles to nothing in release builds.
///
/// Use instead of `print(...)` so shipping builds stay quiet and don't leak
/// internal state to the device console. Call style mirrors `print`.
func log(_ items: Any..., separator: String = " ") {
    #if DEBUG
    print(items.map { "\($0)" }.joined(separator: separator))
    #endif
}
