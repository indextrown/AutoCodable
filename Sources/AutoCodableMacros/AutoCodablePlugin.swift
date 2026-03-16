//
//  AutoCodablePlugin.swift
//  AutoCodable
//
//  Created by 김동현 on 3/16/26.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AutoCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoCodableMacro.self,
        CodableKeyMacro.self
    ]
}
