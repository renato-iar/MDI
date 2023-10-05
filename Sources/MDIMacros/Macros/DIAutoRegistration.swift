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
            let nodeArgumentList = node.arguments?.as(LabeledExprListSyntax.self)
        else {
            context.addDiagnostics(
                from: DIAutoRegistration.Errors.missingArguments,
                node: node
            )

            return []
        }

        guard
            let returnType = nodeArgumentList.first?.expression.as(MemberAccessExprSyntax.self)?.base
        else {
            context.addDiagnostics(
                from: DIAutoRegistration.Errors.missingReturnType,
                node: node
            )

            return []
        }

        guard
            let factory = nodeArgumentList.last?.expression
        else {
            context.addDiagnostics(
                from: DIAutoRegistration.Errors.missingFactory,
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
        case missingArguments
        case missingReturnType
        case missingFactory

        var description: String {
            switch self {
            case .missingArguments:
                return "Require return type and factory method"

            case .missingReturnType:
                return "Missing or un-supported return type"

            case .missingFactory:
                return "Missing or un-supported factory expression"
            }
        }
    }
}
