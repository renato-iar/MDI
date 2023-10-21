import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum DIOpaqueFactoryRegistration { }

// MARK: - MemberMacro

extension DIOpaqueFactoryRegistration: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let factory = SyntaxUtils.getFactoryExpression(from: node)
        else {
            context.addDiagnostics(
                from: DIOpaqueFactoryRegistration.Errors.missingFactory,
                node: node
            )

            return []
        }

        guard
            let registeredType = SyntaxUtils.getRegisteredType(from: node)
        else {
            context.addDiagnostics(
                from: DIOpaqueFactoryRegistration.Errors.missingReturnType,
                node: node
            )

            return []
        }

        let returnType = SyntaxUtils.getPlainType(from: registeredType)
        let factoryTypesFull = SyntaxUtils.getFactoryRegistrableParameterTypes(from: node)
        let factoryTypes = factoryTypesFull.compactMap { $0.resolve ? nil : $0.type }
        let factoryParameters = factoryTypes
            .enumerated()
            .map { index, type in
                "_ arg\(index): \(type)"
            }
            .joined(separator: ", ")

        var argIndex = 0
        let factoryArguments = factoryTypesFull
            .map { resolve, type in
                if resolve {
                    return "Self.resolve(\(type).self)"
                } else {
                    argIndex += 1
                    return "arg\(argIndex-1)"
                }
            }
            .joined(separator: ", ")

        if factoryParameters.isEmpty {
            return [
                    """
                    static func resolve(_: \(registeredType).Type) -> some \(returnType) {
                        return (\(factory))(\(raw: factoryArguments))
                    }
                    """
            ]
        } else {
            return [
                    """
                    static func resolve(_: \(registeredType).Type, \(raw: factoryParameters)) -> some \(returnType) {
                        return (\(factory))(\(raw: factoryArguments))
                    }
                    """
            ]
        }
    }
}

// MARK: - Errors

extension DIOpaqueFactoryRegistration {
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
