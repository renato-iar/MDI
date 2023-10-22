import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MDIPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DIAutoRegistration.self,
        DISingletonRegistration.self,
        DIFactoryAutoRegistration.self,

        DIOpaqueAutoRegistration.self,
        DIOpaqueSingletonRegistration.self,
        DIOpaqueFactoryRegistration.self
    ]
}
