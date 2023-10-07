import Foundation
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
    ) throws -> [DeclSyntax] {
        guard
            let containerName = extractContainerName(from: declaration)
        else {
            context.addDiagnostics(
                from: DISingletonRegistration.Errors.invalidDeclaration,
                node: declaration
            )

            return []
        }

        guard
            let nodeArgumentList = node.arguments?.as(LabeledExprListSyntax.self)
        else {
            context.addDiagnostics(
                from: DISingletonRegistration.Errors.missingArguments,
                node: node
            )

            return []
        }

        guard
            let returnType = nodeArgumentList.first?.expression.as(MemberAccessExprSyntax.self)?.base
        else {
            context.addDiagnostics(
                from: DISingletonRegistration.Errors.missingReturnType,
                node: node
            )
            return []
        }

        guard
            let factory = nodeArgumentList.last?.expression
        else {
            context.addDiagnostics(
                from: DISingletonRegistration.Errors.missingFactory,
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

        let holderTypeName: String

        if let typeName = flattenTypeName(from: returnType) {
            holderTypeName = "\(typeName)_Holder"
        } else {
            holderTypeName = "Holder"
        }

        return [
            """
            static func resolve(_: \(returnType).Type) -> \(returnType) {
                enum \(raw: holderTypeName) {
                    static let shared: \(returnType) = {
                        (\(factory))(\(raw: call))
                    }()
                }
                return \(raw: holderTypeName).shared
            }
            """,

            """
            static func resolve() -> \(returnType) {
                return Self.resolve(\(returnType).self)
            }
            """
        ]
    }
}

// MARK: - Errors

extension DISingletonRegistration {
    enum Errors: Error, CustomStringConvertible {
        case invalidDeclaration
        case missingArguments
        case missingReturnType
        case missingFactory

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
            }
        }
    }
}

// MARK: - Utilities

private extension DISingletonRegistration {
    static func flattenTypeName(from syntax: SyntaxProtocol) -> String? {
        if let identifier = syntax.as(IdentifierTypeSyntax.self) {
            return identifier.name.text
        }

        if let labeledExpression = syntax.as(LabeledExprSyntax.self)?.expression.as(TypeExprSyntax.self) {
            return flattenTypeName(from: labeledExpression)
        }

        if let tuple = syntax.as(TupleExprSyntax.self) {
            if
                tuple.elements.count == 1,
                let containedType = tuple.elements.first
            {
                return flattenTypeName(from: containedType)
            } else {
                return tuple.debugDescription
            }
        }

        if let someOrAnyType = syntax.as(TypeExprSyntax.self)?.type.as(SomeOrAnyTypeSyntax.self) {
            return flattenTypeName(from: someOrAnyType.constraint)
        }

        return nil
    }

    static func extractContainerName(from declaration: DeclGroupSyntax) -> String? {
        if let extendedType = declaration.as(ExtensionDeclSyntax.self)?.extendedType {
            return flattenTypeName(from: extendedType)
        }

        return
            declaration.as(ClassDeclSyntax.self)?.name.text ??
            declaration.as(StructDeclSyntax.self)?.name.text ??
            declaration.as(EnumDeclSyntax.self)?.name.text ??
            declaration.as(ActorDeclSyntax.self)?.name.text
    }
}
