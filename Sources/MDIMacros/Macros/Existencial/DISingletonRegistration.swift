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
            let containerName = SyntaxUtils.getContainerName(from: declaration)
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
            let returnTypeName = SyntaxUtils.getPlainTypeName(from: returnType)
        else {
            context.addDiagnostics(
                from: DISingletonRegistration.Errors.unsupportedType,
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

        let call = SyntaxUtils
            .getFactoryParameterTypes(from: node)
            .map { "\(containerName).resolve(\($0).self)" }
            .joined(separator: ", ")
        let holderTypeName = "\(returnTypeName)_Holder"
        let mockHolderTypeName = "\(returnTypeName)_MockHolder"

        return [
            """
            #if DEBUG
            fileprivate enum \(raw: mockHolderTypeName) {
                static var mock: \(returnType)? = nil
            }
            #endif
            """,

            """
            static func mock(_: \(returnType).Type, singleton: \(returnType)?) {
                #if DEBUG
                \(raw: mockHolderTypeName).mock = singleton
                #endif
            }
            """,

            """
            fileprivate enum \(raw: holderTypeName) {
                static let shared: \(returnType) = {
                    (\(factory))(\(raw: call))
                }()
            }
            """,

            """
            static func resolve(_: \(returnType).Type) -> \(returnType) {
                #if DEBUG
                if let mock = \(raw: mockHolderTypeName).mock { return mock }
                #endif
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
