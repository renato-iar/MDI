import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MDIPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DIAutoRegistration.self,
        DISingletonRegistration.self,
        DIFactoryRegistration.self
    ]
}
