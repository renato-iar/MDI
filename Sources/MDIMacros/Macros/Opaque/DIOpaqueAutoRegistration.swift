import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum DIOpaqueAutoRegistration { }

// MARK: - MemberMacro

extension DIOpaqueAutoRegistration: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let nodeArgumentList = node.arguments?.as(LabeledExprListSyntax.self)
        else {
            context.addDiagnostics(
                from: DIOpaqueAutoRegistration.Errors.missingArguments,
                node: node
            )

            return []
        }

        guard
            let registeredType = nodeArgumentList.first?.expression.as(MemberAccessExprSyntax.self)?.base
        else {
            context.addDiagnostics(
                from: DIOpaqueAutoRegistration.Errors.missingReturnType,
                node: node
            )

            return []
        }

        guard
            let factory = nodeArgumentList.last?.expression
        else {
            context.addDiagnostics(
                from: DIOpaqueAutoRegistration.Errors.missingFactory,
                node: node
            )

            return []
        }

        let returnType = SyntaxUtils.getPlainType(from: registeredType)
        let call = SyntaxUtils
            .getFactoryParameterTypes(from: node)
            .map { "Self.resolve(\($0).self)" }
            .joined(separator: ", ")

        return [
            """
            static func resolve(_: \(registeredType).Type) -> some \(returnType) {
                return (\(factory))(\(raw: call))
            }
            """
        ]
    }
}

// MARK: - Errors

extension DIOpaqueAutoRegistration {
    enum Errors: Error, CustomStringConvertible {
        case missingArguments
        case missingReturnType
        case missingFactory
        case unsupportedType

        var description: String {
            switch self {
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
