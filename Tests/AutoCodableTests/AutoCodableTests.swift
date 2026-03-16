import XCTest
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

@testable import AutoCodableMacros

// 매크로 등록
let testMacros: [String: Macro.Type] = [
    "AutoCodable": AutoCodableMacro.self,
    "CodableKey": CodableKeyMacro.self
]

