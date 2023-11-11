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

        let factoryNamedParameters = SyntaxUtils.getFactoryNamedParameters(from: factory)
        let factoryTypesFull = SyntaxUtils.getFactoryRegistrableParameterTypes(from: node)
        let factoryTypes = factoryTypesFull.compactMap { $0.resolve ? nil : $0.type }
        var argIndex = 0
        var factoryParameters: [String] = []
        var factoryParameterNames: [String] = []
        var factoryArguments: [String] = []

        factoryTypesFull
            .enumerated()
            .forEach {
                guard !$0.element.resolve else {
                    factoryArguments.append("\(containerName).resolve(\($0.element.type).self)")
                    return
                }

                let prefix: String
                let parameter: String

                if
                    let namedParameter = factoryNamedParameters[safe: $0.offset],
                    let namedParameter
                {
                    prefix = ""
                    parameter = namedParameter
                } else {
                    prefix = "_ "
                    parameter = "arg\(argIndex)"
                    argIndex += 1
                }

                factoryParameters.append("\(prefix)\(parameter): \($0.element.type)")
                factoryParameterNames.append(parameter)
                factoryArguments.append(parameter)
            }

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
                    """,

                    """
                    static func factory(of _: \(returnType).Type) -> MDIFactory<\(returnType)> {
                        return MDIFactory {
                            return resolve(\(returnType).self)
                        }
                    }
                    """
            ]
            )
        } else {
            declarations.append(contentsOf: [
                    """
                    static func resolve(_: \(returnType).Type, \(raw: factoryParameters.joined(separator: ", "))) -> \(returnType) {
                        #if DEBUG
                        \(raw: SyntaxUtils.generateMockFunctionCall(with: returnTypePlainName, arguments: factoryParameterNames))
                        #endif
                        return (\(factory))(\(raw: factoryArguments.joined(separator: ", ")))
                    }
                    """,

                    """
                    static func resolve(\(raw: factoryParameters.joined(separator: ", "))) -> \(returnType) {
                        return \(raw: containerName).resolve(\(returnType).self, \(raw: factoryParameterNames.map{ "\($0): \($0)" }.joined(separator: ", ")))
                    }
                    """,

                    """
                    struct \(raw: returnTypePlainName)Factory {
                        fileprivate init() {}

                        public func make(\(raw: factoryParameters.joined(separator: ", "))) -> \(returnType) {
                            return \(raw: containerName).resolve(\(returnType).self, \(raw: factoryParameterNames.map{ "\($0): \($0)" }.joined(separator: ", ")))
                        }
                    }
                    """,

                    """
                    static func factory(of: \(returnType).Type) -> \(raw: returnTypePlainName)Factory {
                        return \(raw: returnTypePlainName)Factory()
                    }
                    """,

                    """
                    static func factory(of: \(returnType).Type, \(raw: factoryParameters.joined(separator: ", "))) -> MDIFactory<\(returnType)> {
                        return MDIFactory {
                            return \(raw: containerName).resolve(\(returnType).self, \(raw: factoryParameterNames.map{ "\($0): \($0)" }.joined(separator: ", ")))
                        }
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
