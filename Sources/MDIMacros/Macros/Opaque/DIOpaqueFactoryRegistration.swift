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

        guard
            let containerName = SyntaxUtils.getContainerName(from: declaration)
        else {
            context.addDiagnostics(
                from: DIOpaqueFactoryRegistration.Errors.invalidDeclaration,
                node: declaration
            )
            return []
        }

        let returnType = SyntaxUtils.getPlainType(from: registeredType)

        guard
            let returnTypePlainName = SyntaxUtils.getPlainTypeName(from: returnType)
        else {
            context.addDiagnostics(
                from: DIOpaqueFactoryRegistration.Errors.unsupportedType,
                node: returnType
            )
            return []
        }

        let factoryTypesFull = SyntaxUtils.getFactoryRegistrableParameterTypes(from: node)
        let factoryNamedParameters = SyntaxUtils.getFactoryNamedParameters(from: factory)

        var argIndex = 0
        var factoryParameterNamesArray: [String] = []
        var factoryParametersArray: [String] = []
        var factoryArgumentsArray: [String] = []

        factoryTypesFull
            .enumerated()
            .forEach {
                let index = $0.offset
                let resolve = $0.element.resolve
                let type = $0.element.type

                if resolve {
                    factoryArgumentsArray.append("\(containerName).resolve(\(type).self)")
                } else
                if
                    let namedParameter = factoryNamedParameters[safe: index],
                    let namedParameter
                {
                    factoryParameterNamesArray.append(namedParameter)
                    factoryParametersArray.append("\(namedParameter): \(type)")
                    factoryArgumentsArray.append(namedParameter)
                } else {
                    factoryParameterNamesArray.append("arg\(argIndex)")
                    factoryParametersArray.append("_ arg\(argIndex): \(type)")
                    factoryArgumentsArray.append("arg\(argIndex)")
                    argIndex += 1
                }
            }

        let factoryParameters = factoryParametersArray.joined(separator: ", ")
        let factoryArguments = factoryArgumentsArray.joined(separator: ", ")

        if factoryParameters.isEmpty {
            return [
                    """
                    static func resolve(_: \(registeredType).Type) -> some \(returnType) {
                        return (\(factory))(\(raw: factoryArguments))
                    }
                    """,

                    """
                    static func factory(of _: \(registeredType).Type) -> MDIFactory<some \(returnType)> {
                        return MDIFactory {
                            return resolve(\(registeredType).self)
                        }
                    }
                    """
            ]
        } else {
            return [
                    """
                    static func resolve(_: \(registeredType).Type, \(raw: factoryParameters)) -> some \(returnType) {
                        return (\(factory))(\(raw: factoryArguments))
                    }
                    """,

                    """
                    struct \(raw: returnTypePlainName)Factory {
                        fileprivate init() {}

                        public func make(\(raw: factoryParameters)) -> some \(returnType) {
                            return \(raw: containerName).resolve(\(registeredType).self, \(raw: factoryParameterNamesArray.map { "\($0): \($0)" }.joined(separator: ", ")))
                        }
                    }
                    """,

                    """
                    static func factory(of: \(registeredType).Type) -> \(raw: returnTypePlainName)Factory {
                        return \(raw: returnTypePlainName)Factory()
                    }
                    """,

                    """
                    static func factory(of: \(registeredType).Type, \(raw: factoryParameters)) -> MDIFactory<some \(returnType)> {
                        return MDIFactory {
                            \(raw: containerName).resolve(\(registeredType).self, \(raw: factoryParameterNamesArray.map{ "\($0): \($0)" }.joined(separator: ", ")))
                        }
                    }
                    """
            ]
        }
    }
}

// MARK: - Errors

extension DIOpaqueFactoryRegistration {
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
