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
        guard
            let containerName = SyntaxUtils.getContainerName(from: declaration)
        else {
            context.addDiagnostics(
                from: DIAutoRegistration.Errors.invalidDeclaration,
                node: declaration
            )

            return []
        }

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
            repeating: "\(containerName).resolve()",
            count: numberOfFactoryArguments
        ).joined(separator: ", ")

        guard let returnTypeName = SyntaxUtils.getPlainTypeName(from: returnType) else {
            context.addDiagnostics(
                from: DIAutoRegistration.Errors.unsupportedType,
                node: declaration
            )
            return []
        }

        var declarations = SyntaxUtils.generateMockFunction(for: returnType, with: returnTypeName)

        declarations.append(contentsOf: [
            """
            static func resolve(_: \(returnType).Type) -> \(returnType) {
                #if DEBUG
                \(raw: SyntaxUtils.generateMockFunctionCall(with: returnTypeName))
                #endif
                return (\(factory))(\(raw: call))
            }
            """,

            """
            static func resolve() -> \(returnType) {
                return resolve(\(returnType).self)
            }
            """
        ])

        return declarations
    }
}

// MARK: - Errors

extension DIAutoRegistration {
    enum Errors: Error, CustomStringConvertible {
        case invalidDeclaration
        case missingArguments
        case missingReturnType
        case missingFactory
        case unsupportedType

        var description: String {
            switch self {
            case .invalidDeclaration:
                return "Macro must be applied to type declarations or extensions"

            case .missingArguments:
                return "Require return type and factory method"

            case .missingReturnType:
                return "Missing or un-supported return type"

            case .missingFactory:
                return "Missing or un-supported factory expression"

            case .unsupportedType:
                return "Registered type is not supported"
            }
        }
    }
}
