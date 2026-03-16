//
//  CodableKeyMacro.swift
//  AutoCodable
//
//  Created by 김동현 on 3/16/26.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct CodableKeyMacro: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        /**
         이 매크로는 실제 코드를 생성하지 않습니다
         단순 attribute의 marker로 유지합니다
         @CodableKey(name: "user_profile_url")
         */
        return []
    }
}
