import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum DIFactoryAutoRegistration { }

// MARK: - MemberMacro

extension DIFactoryAutoRegistration: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let containerName = SyntaxUtils.getContainerName(from: declaration)
        else {
            context.addDiagnostics(
                from: DIFactoryAutoRegistration.Errors.invalidDeclaration,
                node: declaration
            )

            return []
        }

        guard
            let factory = SyntaxUtils.getFactoryExpression(from: node)
        else {
            context.addDiagnostics(
                from: DIFactoryAutoRegistration.Errors.missingFactory,
                node: node
            )

            return []
        }

        guard
            let returnType = SyntaxUtils.getRegisteredType(from: node)
        else {
            context.addDiagnostics(
                from: DIFactoryAutoRegistration.Errors.missingReturnType,
                node: node
            )

            return []
        }

        let factoryTypesFull = SyntaxUtils.getFactoryRegistrableParameterTypes(from: node)
        let factoryTypes = factoryTypesFull.compactMap { $0.resolve ? nil : $0.type }
        let factoryParameters = factoryTypes
            .enumerated()
            .map { index, type in
                "_ arg\(index): \(type)"
            }
            .joined(separator: ", ")
        let factoryParameterNames = (0 ..< factoryTypes.count).map { "arg\($0)" }
        var argIndex = 0
        let factoryArguments = factoryTypesFull
            .map { resolve, type in
                if resolve {
                    return "\(containerName).resolve()"
                } else {
                    argIndex += 1
                    return "arg\(argIndex-1)"
                }
            }
            .joined(separator: ", ")
        let publicFactoryArguments = factoryParameterNames.joined(separator: ", ")

        guard let returnTypePlainName = SyntaxUtils.getPlainTypeName(from: returnType) else {
            context.addDiagnostics(
                from: DIFactoryAutoRegistration.Errors.unsupportedType,
                node: declaration
            )

            return []
        }

        var declarations: [DeclSyntax] = SyntaxUtils.generateMockFunction(
            for: returnType,
            with: returnTypePlainName,
            parameters: factoryTypes
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
                        \(raw: SyntaxUtils.generateMockFunctionCall(with: returnTypePlainName, arguments: factoryParameterNames))
                        #endif
                        return (\(factory))(\(raw: factoryArguments))
                    }
                    """,

                    """
                    static func resolve(\(raw: factoryParameters)) -> \(returnType) {
                        return resolve(\(returnType).self, \(raw: publicFactoryArguments))
                    }
                    """
            ]
            )
        }

        return declarations
    }
}

// MARK: - Errors

extension DIFactoryAutoRegistration {
    enum Errors: Error, CustomStringConvertible {
        case invalidDeclaration
        case missingReturnType
        case missingFactory
        case unsupportedType

        var description: String {
            switch self {
            case .invalidDeclaration:
                return "Macro must be applied to type declarations or extensions"

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
