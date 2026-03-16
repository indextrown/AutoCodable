import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AutoCodableMacro: MemberMacro, ExtensionMacro {
    // MARK: - CodingKeys 생성
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            return []
        }
        
        var cases: [String] = []
        for member in structDecl.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }
            
            guard let binding = variable.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
            else {
                continue
            }
            
            let propertyName = identifier.identifier.text
            var codingKey = propertyName
            
            // MARK: - Codable attribute 확인
            for attr in variable.attributes {
                guard let attribute = attr.as(AttributeSyntax.self) else {
                    continue
                }
                let name = attribute.attributeName.description.trimmingCharacters(in: .whitespaces)
                if name == "CodableKey" {
                    if let arguments = attribute.arguments?.as(LabeledExprListSyntax.self),
                       let first = arguments.first {
                        
                        codingKey = first.expression.description
                            .replacingOccurrences(of: "\"", with: "")
                    }
                    
                }
            }
            
            // MARK: - Case 생성
            if codingKey == propertyName {
                cases.append("    case \(propertyName)")
            } else {
                cases.append("    case \(propertyName) = \"\(codingKey)\"")
            }
        }
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
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        // struct가 아니면 extension 생성 안함
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
}
