import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum DIAutoRegistration { }

// MARK: - MemberMacro

extension DIAutoRegistration: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        var dumped = ""
        dump(node, to: &dumped)

        guard
            let nodeArgumentList = node.arguments?.as(LabeledExprListSyntax.self),
            nodeArgumentList.count == 2,
            let returnType = nodeArgumentList.first?.expression.as(MemberAccessExprSyntax.self)?.base,
            let factory = nodeArgumentList.last?.expression
        else {
            context.addDiagnostics(
                from: DIAutoRegistration.Errors.indexedError(1, node: dumped),
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

        return [
            """
            static func resolve(_: \(returnType).Type) -> \(returnType) {
                return (\(factory))(\(raw: call))
            }
            """,

            """
            static func resolve() -> \(returnType) {
                return resolve(\(returnType).self)
            }
            """
        ]
    }
}

// MARK: - Errors

extension DIAutoRegistration {
    enum Errors: Error, CustomStringConvertible {
        case undefinedReturnType
        case indexedError(Int, node: String? = nil)

        var description: String {
            switch self {
            case .undefinedReturnType:
                return "Missing macro generic necessary for return type"

            case let .indexedError(index, node: node?):
                return "Error #\(index): \(node)"

            case let .indexedError(index, node: _):
                return "Error #\(index)"
            }
        }
    }
}
