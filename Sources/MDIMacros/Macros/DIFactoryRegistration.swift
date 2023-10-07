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
        guard
            let factory = SyntaxUtils.getFactoryExpression(from: node)
        else {
            context.addDiagnostics(
                from: DIFactoryRegistration.Errors.missingFactory,
                node: node
            )

            return []
        }

        guard
            let returnType = SyntaxUtils.getRegisteredType(from: node)
        else {
            context.addDiagnostics(
                from: DIFactoryRegistration.Errors.missingReturnType,
                node: node
            )

            return []
        }

        let factoryTypes = SyntaxUtils.getFactoryParameterTypes(from: node)
        let factoryParameters = factoryTypes
            .enumerated()
            .map { index, type in
                "_ arg\(index): \(type)"
            }
            .joined(separator: ", ")
        let factoryArguments = factoryTypes.enumerated().map { index, _ in "arg\(index)" }.joined(separator: ", ")

        guard let returnTypePlainName = SyntaxUtils.getPlainTypeName(from: returnType) else {
            context.addDiagnostics(
                from: DIFactoryRegistration.Errors.unsupportedType,
                node: declaration
            )

            return []
        }

        var declarations: [DeclSyntax] = SyntaxUtils.generateMockFunction(
            for: returnType,
            with: returnTypePlainName
        )

        if factoryTypes.isEmpty {
            declarations.append(contentsOf: [
                    """
                    static func resolve(_: \(returnType).Type) -> \(returnType) {
                        #if DEBUG
                        \(raw: SyntaxUtils.generateMockFunctionCall(with: returnTypePlainName))
                        #endif
                        return (\(factory))()
                    }
                    """,
                    """
                    static func resolve() -> \(returnType) {
                        return resolve(\(returnType).self)
                    }
                    """
                ]
            )
        } else {
            declarations.append(contentsOf: [
                    """
                    static func resolve(_: \(returnType).Type, \(raw: factoryParameters)) -> \(returnType) {
                        #if DEBUG
                        \(raw: SyntaxUtils.generateMockFunctionCall(with: returnTypePlainName))
                        #endif
                        return (\(factory))(\(raw: factoryArguments))
                    }
                    """,

                    """
                    static func resolve(\(raw: factoryParameters)) -> \(returnType) {
                        return (\(factory))(\(raw: factoryArguments))
                    }
                    """
                ]
            )
        }

        return declarations
    }
}

// MARK: - Errors

extension DIFactoryRegistration {
    enum Errors: Error, CustomStringConvertible {
        case missingReturnType
        case missingFactory
        case unsupportedType

        var description: String {
            switch self {
            case .missingReturnType:
                return "Macro expects return type at first argument"

            case .missingFactory:
                return "Macro expects factory as last argument"

            case .unsupportedType:
                return "Registered type is not supported"
            }
        }
    }
}
