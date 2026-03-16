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

final class AutoCodableTests: XCTestCase {
    func test_AutoCodable이_기본_프로퍼티로_CodingKeys를_생성한다() {
        assertMacroExpansion(
            """
            @AutoCodable
            struct Person {
                let name: String
                let age: Int
            }
            """,
            expandedSource:
            """
            struct Person {
                let name: String
                let age: Int
            
                private enum CodingKeys: String, CodingKey {
                    case name
                    case age
                }
            }
            
            extension Person: Codable {
            }
            """,
            macros: testMacros
        )
    }
    
    func test_CodableKey_매크로를_사용하면_JSON키를_변경한다() {
        assertMacroExpansion(
            """
            @AutoCodable
            struct Person {
                let name: String
                let age: Int
            
                @CodableKey(name: "user_profile_url")
                let profileURL: String
            }
            """,
            expandedSource:
            """
            struct Person {
                let name: String
                let age: Int
                let profileURL: String
            
                private enum CodingKeys: String, CodingKey {
                    case name
                    case age
                    case profileURL = "user_profile_url"
                }
            }
            
            extension Person: Codable {
            }
            """,
            macros: testMacros
        )
    }
    
    func test_struct가_아니면_매크로가_동작하지_않는다() {
        assertMacroExpansion(
            """
            @AutoCodable
            class Person {
                let name: String
            }
            """,
            expandedSource:
            """
            class Person {
                let name: String
            }
            """,
            macros: testMacros
        )
    }
}
