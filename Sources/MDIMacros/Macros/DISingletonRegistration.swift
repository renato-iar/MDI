import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum DISingletonRegistration { }

// MARK: - MemberMacro

extension DISingletonRegistration: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        var dumped = ""
        dump(node, to: &dumped)

        guard
            let nodeArgumentList = node.arguments?.as(LabeledExprListSyntax.self)
        else {
            context.addDiagnostics(
                from: DIAutoRegistration.Errors.indexedError(1, node: dumped),
                node: node
            )
            return []
        }

        guard
            nodeArgumentList.count == 2
        else {
            context.addDiagnostics(
                from: DIAutoRegistration.Errors.indexedError(2, node: dumped),
                node: node
            )
            return []
        }

        guard
            let returnType = nodeArgumentList.first?.expression.as(MemberAccessExprSyntax.self)?.base
        else {
            context.addDiagnostics(
                from: DIAutoRegistration.Errors.indexedError(3, node: dumped),
                node: node
            )
            return []
        }

        guard
            let factory = nodeArgumentList.last?.expression
        else {
            context.addDiagnostics(
                from: DIAutoRegistration.Errors.indexedError(4, node: dumped),
                node: node
            )
            return []
        }

        let numberOfFactoryArguments: Int = {
            factory
                .as(MemberAccessExprSyntax.self)?
                .declName
                .argumentNames?
                .arguments
                .count ?? 0
        }()

        let call = Array(
            repeating: "Self.resolve()",
            count: numberOfFactoryArguments
        ).joined(separator: ", ")

        let singletonName = context.makeUniqueName("shared")

        return [
            """
            fileprivate static let \(singletonName): \(returnType) = {
                return (\(factory))(\(raw: call))
            }()
            """,

            """
            static func resolve(_: \(returnType).Type) -> \(returnType) {
                return \(singletonName)
            }
            """,

            """
            static func resolve() -> \(returnType) {
                return \(singletonName)
            }
            """
        ]
    }
}
