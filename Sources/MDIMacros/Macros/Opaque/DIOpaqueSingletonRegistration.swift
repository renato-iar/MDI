import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum DIOpaqueSingletonRegistration { }

// MARK: - MemberMacro

extension DIOpaqueSingletonRegistration: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let containerName = SyntaxUtils.getContainerName(from: declaration)
        else {
            context.addDiagnostics(
                from: DIOpaqueSingletonRegistration.Errors.invalidDeclaration,
                node: declaration
            )

            return []
        }

        guard
            let nodeArgumentList = node.arguments?.as(LabeledExprListSyntax.self)
        else {
            context.addDiagnostics(
                from: DIOpaqueSingletonRegistration.Errors.missingArguments,
                node: node
            )

            return []
        }

        guard
            let registeredType = nodeArgumentList.first?.expression.as(MemberAccessExprSyntax.self)?.base
        else {
            context.addDiagnostics(
                from: DIOpaqueSingletonRegistration.Errors.missingReturnType,
                node: node
            )
            return []
        }

        guard
            let returnTypeName = SyntaxUtils.getPlainTypeName(from: registeredType)
        else {
            context.addDiagnostics(
                from: DIOpaqueSingletonRegistration.Errors.unsupportedType,
                node: node
            )
            return []
        }

        guard
            let factory = nodeArgumentList.last?.expression
        else {
            context.addDiagnostics(
                from: DIOpaqueSingletonRegistration.Errors.missingFactory,
                node: node
            )
            return []
        }

        let returnType = SyntaxUtils.getPlainType(from: registeredType)
        let call = SyntaxUtils
            .getFactoryParameterTypes(from: node)
            .map { "\(containerName).resolve(\($0).self)" }
            .joined(separator: ", ")

        let holderTypeName = "\(returnTypeName)_Holder"

        return [
            """
            fileprivate enum \(raw: holderTypeName) {
                static let shared: some \(returnType) = (\(factory))(\(raw: call))
            }
            """,

            """
            static func resolve(_: \(registeredType).Type) -> some \(returnType) {
                return \(raw: holderTypeName).shared
            }
            """
        ]
    }
}

// MARK: - Errors

extension DIOpaqueSingletonRegistration {
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
