import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


/**
 MemberMacro
 - 타입 내부에 코드 생성
 - struct 내부에 CodingKeys enum 생성
 ExtensionMacro
 - 타입 외부에 extension 생성
 - struct 외부에 extension Codable 생성
 */
public struct AutoCodableMacroLegacy: MemberMacro, ExtensionMacro {
    // MARK: - CodingKeys 생성
    
    /// struct의 프로퍼티를 분석하여 CodingKeys enum을 자동 생성합니다.
    /// - Parameters:
    ///   - node: @AutoCodable attribute 정보
    ///   - declaration: 매크로가 붙은 타입 선언(ex: `struct Person`)
    ///   - context: 매크로 확장 환경 정보
    /// - Returns: SwiftSyntax 선언 목록 `[DeclSyntax]` == 생성할 코드 목록
    /// private enum CodingKeys: String, CodingKey {
    /// case name
    /// }
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        /// 매크로가 struct에만 동작하도록 제한
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            return []
        }
        
        // MARK: - SnakeCase
        var style: String = "userDefault"
        if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
            for arg in arguments {
                if arg.label?.text == "codingKeyStyle" {
                    style = arg.expression.description
                        .replacingOccurrences(of: ".", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        /// 생성할 CodingKeys case 문자열 목록
        var cases: [String] = []
        
        /// struct 내부 모든 멤버 순회
        for member in structDecl.memberBlock.members {
            
            /// 변수 선언(var  / let)만 처리
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }
            
            /// static 제외
            if variable.modifiers.contains(where: { $0.name.text == "static" }) {
                continue
            }
            
            /// Swift에서는 `var a, b: Int` 처럼 하나의 변수 선언에 여러 프로퍼티가 포함될 수 있으므로 bindings 전체를 순회합니다
            for binding in variable.bindings {
                
                // computed property 제외
                if binding.accessorBlock != nil {
                    continue
                }
                
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }
                
                /// Swift 프로퍼티 이름
                /// ex)  userProfileURL
                let propertyName = identifier.identifier.text
                
                /// JSON key 이름
                /// 기본값은 propertyName와 동일
                var codingKey = propertyName
                
                // MARK: - Codable attribute 확인
                var hasCustomKey = false
                
                /// 프로퍼티에 붙은 attribute 검사
                /// ex) @CodableKey(name: "user_profile_url")
                for attr in variable.attributes {
                    
                    guard let attribute = attr.as(AttributeSyntax.self) else {
                        continue
                    }
                    
                    /// attribute 이름
                    let name = attribute.attributeName.description
                        .trimmingCharacters(in: .whitespaces)
                    
                    /// CodableKey attribute 발견시
                    if name == "CodableKey" {
                        
                        /// attribute argument 목록
                        /// ex) name: "user_profile_url"
                        if let arguments = attribute.arguments?.as(LabeledExprListSyntax.self),
                           let first = arguments.first {
                            
                            /// JSON key 문자열 추출
                            codingKey = first.expression.description
                                .replacingOccurrences(of: "\"", with: "")
                            hasCustomKey = true
                        }
                    }
                }
                
                if !hasCustomKey {
                    if style == "snakeCase" {
                        codingKey = toSnakeCase(propertyName)
                    }
                }
                
                // MARK: - Case 생성
                if codingKey == propertyName {
                    /// case name
                    cases.append("    case \(propertyName)")
                } else {
                    /// case userProfileURL = "user_profile_url"
                    cases.append("    case \(propertyName) = \"\(codingKey)\"")
                }
            }
        }
        
        /// CodingKeys 코드 생성
        let codingKeysEnum =
        """
        private enum CodingKeys: String, CodingKey {
        \(cases.joined(separator: "\n"))
        }
        """
        return [
            DeclSyntax(stringLiteral: codingKeysEnum)
        ]
    }
    
    
    // MARK: - Codable extension 생성
    
    
    /// struct에 Codable 프로토콜을 자동으로 추가합니다
    /// - Parameters:
    ///   - node: `@AutoCodable` attribute 정보
    ///   - declaration: 매크로가 붙은 타입 선언
    ///   - type: extension을 적용할 타입 (ex: `Person`)
    ///   - protocols: 기존 protocol 목록
    ///   - context: 매크로 확장 환경 정보
    /// - Returns: 생성된 extension 선언 `ExtensionDeclSyntax`
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        // struct가 아니면 extension 생성 안하고 종료합니다
        guard declaration.is(StructDeclSyntax.self) else {
            return []
        }
        
        let extensionDecl: DeclSyntax =
    """
    extension \(type): Codable {}
    """
        return [extensionDecl.cast(ExtensionDeclSyntax.self)]
        
        /*
         return [
         try ExtensionDeclSyntax("extension \(type): Codable {}")
         ]
         */
    }
    
    static func toSnakeCase(_ input: String) -> String {
        var result = ""
        
        for char in input {
            if char.isUppercase {
                if !result.isEmpty {
                    result += "_"
                }
                result += char.lowercased()
            } else {
                result += String(char)
            }
        }
        
        return result
    }
}
