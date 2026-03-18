import SwiftSyntax
import Foundation
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
public struct AutoCodableMacro: MemberMacro, ExtensionMacro {
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
        
        let style = parseStyle(node: node)
        let cases = extractCodingKeys(from: structDecl, style: style)
        return [makeCodingKeysEnum(from: cases)]
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
        
        if protocols.contains(where: { $0.description == "Codable" }) {
            return []
        }
        
        let extensionDecl: DeclSyntax =
        """
        extension \(type): Codable {}
        """
        return [extensionDecl.cast(ExtensionDeclSyntax.self)]
    }
    

}

private extension AutoCodableMacro {
    
    /// `@AutoCodable` attribute에 전달된 옵션 중 `codingKeyStyle` 값을 추출합니다.
    ///
    /// - Parameter node: 매크로 attribute (`@AutoCodable(...)`)
    /// - Returns: coding key 변환 스타일 (기본값: `"useDefault"`)
    ///
    /// - Note:
    ///   - `@AutoCodable(codingKeyStyle: .snakeCase)` → `"snakeCase"`
    ///   - 옵션이 없으면 `"useDefault"` 반환
    static func parseStyle(node: AttributeSyntax) -> String {
        if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
            for arg in arguments {
                if arg.label?.text == "codingKeyStyle" {
                    return arg.expression.description
                        .replacingOccurrences(of: ".", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return "useDefault"
    }
    
    // MARK: - PropertyName 추출
    /// 변수 바인딩(PatternBinding)으로부터 실제 프로퍼티 이름을 추출합니다.
    ///
    /// - Parameter binding: SwiftSyntax의 PatternBinding
    /// - Returns: 프로퍼티 이름 (`String`) 또는 nil
    ///
    /// - Note:
    ///   - computed property는 제외됩니다 (`accessorBlock != nil`)
    ///   - ex) `var userName: String` → `"userName"`
    static func extractPropertyName(
        from binding: PatternBindingSyntax
    ) -> String? {
        if binding.accessorBlock != nil { return nil }
        return binding.pattern
            .as(IdentifierPatternSyntax.self)?
            .identifier.text
    }
    
    // MARK: - CodableKey 추출
    /// `@CodableKey(name:)` attribute가 존재하는 경우 해당 값을 추출합니다.
    ///
    /// - Parameter variable: 변수 선언 (`VariableDeclSyntax`)
    /// - Returns: 사용자 지정 CodingKey 문자열 또는 nil
    ///
    /// - Example:
    ///   ```swift
    ///   @CodableKey(name: "user_profile_url")
    ///   var userProfileURL: String
    ///   ```
    ///   → `"user_profile_url"`
    ///
    /// - Note:
    ///   - attribute가 없으면 nil 반환
    ///   - 이후 기본 규칙(snakeCase 등)이 적용됩니다
    static func extractCustomKey(
        from variable: VariableDeclSyntax
    ) -> String? {
        for attr in variable.attributes {
            guard let attribute = attr.as(AttributeSyntax.self) else {
                continue
            }
            
            let name = attribute.attributeName.description
                .trimmingCharacters(in: .whitespaces)
            
            if name == "CodableKey" {
                if let arguments = attribute.arguments?.as(LabeledExprListSyntax.self),
                   let first = arguments.first {
                
                    return first.expression.description
                        .replacingOccurrences(of: "\"", with: "")
                }
            
            }
        }
        return nil
    }
    
    // MARK: - Case 생성
    /// CodingKeys enum에 들어갈 case 문자열을 생성합니다.
    ///
    /// - Parameters:
    ///   - propertyName: Swift 프로퍼티 이름
    ///   - codingKey: JSON key 이름
    /// - Returns: enum case 문자열
    ///
    /// - Example:
    ///   - 동일한 경우 → `case name`
    ///   - 다른 경우 → `case userProfileURL = "user_profile_url"`
    ///
    /// - Note:
    ///   - propertyName은 Swift 코드 기준
    ///   - codingKey는 JSON key 기준
    static func makeCase(propertyName: String, codingKey: String) -> String {
        if propertyName == codingKey {
            /// case name
            return "    case \(propertyName)"
        } else {
            /// case userProfileURL = "user_profile_url"
            return "    case \(propertyName) = \"\(codingKey)\""
        }
    }
    
    // MARK: - snakeCase 반환
    /// camelCase 문자열을 snake_case로 변환합니다.
    ///
    /// - Parameter input: 변환할 문자열
    /// - Returns: snake_case 문자열
    ///
    /// - Example:
    ///   - `userName` → `user_name`
    ///   - `userProfileURL` → `user_profile_u_r_l` (현재 단순 알고리즘)
    ///
    /// - Note:
    ///   - 현재는 단순 대문자 기준 변환
    ///   - `userID → user_id` 처리는 추가 개선 가능
    static func toSnakeCase(_ input: String) -> String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: input.count)
        
        let result = regex.stringByReplacingMatches(
            in: input,
            range: range,
            withTemplate: "$1_$2"
        )
        
        return result.lowercased()
    }
    
    // MARK: - CodingKey 결정
    /// 최종 CodingKey 값을 결정합니다.
    ///
    /// - Parameters:
    ///   - propertyName: Swift 프로퍼티 이름
    ///   - variable: 변수 선언
    ///   - style: 변환 스타일 (useDefault / snakeCase)
    /// - Returns: 최종 JSON key 문자열
    ///
    /// - 우선순위:
    ///   1. `@CodableKey` 존재 → 해당 값 사용
    ///   2. snakeCase 옵션 → 변환 적용
    ///   3. 기본값 → propertyName 그대로 사용
    static func resolveCodingKey(
        propertyName: String,
        variable: VariableDeclSyntax,
        style: String
    ) -> String {
        if let custom = extractCustomKey(from: variable) {
            return custom
        }
        
        if style == "snakeCase" {
            return toSnakeCase(propertyName)
        }
        
        return propertyName
    }
    
    // MARK: - CodingKeys 배열 생성
    /// 최종 CodingKey 값을 결정합니다.
    ///
    /// - Parameters:
    ///   - propertyName: Swift 프로퍼티 이름
    ///   - variable: 변수 선언
    ///   - style: 변환 스타일 (useDefault / snakeCase)
    /// - Returns: 최종 JSON key 문자열
    ///
    /// - 우선순위:
    ///   1. `@CodableKey` 존재 → 해당 값 사용
    ///   2. snakeCase 옵션 → 변환 적용
    ///   3. 기본값 → propertyName 그대로 사용
    static func extractCodingKeys(
        from structDecl: StructDeclSyntax,
        style: String
    ) -> [String] {
        var cases: [String] = []
        
        for member in structDecl.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }
            
            if variable.modifiers.contains(where: { $0.name.text == "static" }) {
                continue
            }
            
            for binding in variable.bindings {
                guard let propertyName = extractPropertyName(from: binding) else {
                    continue
                }
                
                let codingKey = resolveCodingKey(
                    propertyName: propertyName,
                    variable: variable,
                    style: style
                )
                
                cases.append(makeCase(propertyName: propertyName, codingKey: codingKey))
            }
        }
        
        return cases
    }
    
    // MARK: - CodingKeys enum 생성
    /// CodingKeys enum 전체 코드를 생성합니다.
    ///
    /// - Parameter cases: case 문자열 배열
    /// - Returns: SwiftSyntax DeclSyntax (enum 코드)
    ///
    /// - Example:
    ///   ```swift
    ///   private enum CodingKeys: String, CodingKey {
    ///       case name
    ///       case userProfileURL = "user_profile_url"
    ///   }
    ///   ```
    static func makeCodingKeysEnum(from cases: [String]) -> DeclSyntax {
        let code =
        """
        private enum CodingKeys: String, CodingKey {
        \(cases.joined(separator: "\n"))
        }
        """
        return DeclSyntax(stringLiteral: code)
    }
    
}
