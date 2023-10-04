import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum DIFactoryRegistration { }

// MARK: - MemberMacro

extension DIFactoryRegistration: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let factory = try extractFactory(from: node)
        let returnType = try extractReturnType(from: node)
        let factoryTypes = extractFactoryTypes(from: node)
        let factoryParameters = factoryTypes
            .enumerated()
            .map { index, type in
                "_ arg\(index): \(type)"
            }
            .joined(separator: ", ")
        let factoryArguments = factoryTypes.enumerated().map { index, _ in "arg\(index)" }.joined(separator: ", ")

        if factoryTypes.isEmpty {
            return [
                """
                static func resolve(_: \(returnType).Type) -> \(returnType) {
                    return (\(factory))()
                }
                """
            ]
        } else {
            return [
                """
                static func resolve(_: \(returnType).Type, \(raw: factoryParameters)) -> \(returnType) {
                    return (\(factory))(\(raw: factoryArguments))
                }
                """,

                """
                static func resolve(\(raw: factoryParameters)) -> \(returnType) {
                    return (\(factory))(\(raw: factoryArguments))
                }
                """
            ]
        }
    }
}

// MARK: - Errors

extension DIFactoryRegistration {
    enum Errors: Error, CustomStringConvertible {
        case missingReturnType
        case missingFactory
        case indexedError(index: Int, dump: String?)

        var description: String {
            switch self {
            case .missingReturnType:
                return "Macro expects return type at first argument"

            case .missingFactory:
                return "Macro expects factory as last argument"

            case let .indexedError(index: index, dump: dump?):
                return "Error @[\(index)]: \(dump)"

            case let .indexedError(index: index, dump: _):
                return "Error @[\(index)]"
            }
        }
    }
}

// MARK: - Utils

private extension DIFactoryRegistration {
    static func extractReturnType(from node: AttributeSyntax) throws -> ExprSyntax {
        guard
            let returnType = node
                .arguments?
                .as(LabeledExprListSyntax.self)?
                .first?
                .as(LabeledExprSyntax.self)?
                .expression
                .as(MemberAccessExprSyntax.self)?
                .base
        else {
            throw DIFactoryRegistration.Errors.missingReturnType
        }

        return returnType
    }

    static func extractFactoryTypes(from node: AttributeSyntax) -> [ExprSyntax] {
        guard
            let types = node.arguments?.as(LabeledExprListSyntax.self)?.compactMap({ $0 }),
            types.count > 2
        else {
            return []
        }

        return (1 ..< types.count - 1).compactMap { index in
            types[index].as(LabeledExprSyntax.self)?.expression.as(MemberAccessExprSyntax.self)?.base
        }
    }

    static func extractFactory(from node: AttributeSyntax) throws -> ExprSyntax {
        guard
            let arguments = node
                .arguments?
                .as(LabeledExprListSyntax.self),
            arguments.count > 1,
            let factory = arguments
                .last?
                .as(LabeledExprSyntax.self)?
                .expression
        else {
            throw DIFactoryRegistration.Errors.missingFactory
        }

        return factory
    }
}
