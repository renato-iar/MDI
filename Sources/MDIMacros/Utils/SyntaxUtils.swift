import SwiftSyntax
import SwiftSyntaxBuilder

enum SyntaxUtils {
    /**
     Generates the mock functionality

     For mocking purposes, `generateMockDecl` will expose the mocking function, contained within the specified holder

     - parameters:
        - returnType the mocked type
        - mockHolderName the name of the mock holder type that will hold the mock

     - returns the necessary declarations to store the mock

     - note the store type for the mock will be declared in the generated declarations
     */
    static func generateMockFunction(
        for returnType: SyntaxProtocol,
        with plainTypeName: String,
        parameters: [SyntaxProtocol] = []
    ) -> [DeclSyntax] {
        let mockHolderName = "\(plainTypeName)_MockHolder"
        let functionTypes = parameters.map { $0.description }.joined(separator: ", ")

        return [
            """
            #if DEBUG
            fileprivate enum \(raw: mockHolderName) {
                static var mock: ((\(raw: functionTypes)) -> \(returnType))? = nil
            }
            #endif
            """,

            """
            static func mock(_: \(returnType).Type, factory: ((\(raw: functionTypes)) -> \(returnType))?) {
                #if DEBUG
                \(raw: mockHolderName).mock = factory
                #endif
            }
            """
        ]
    }

    /**
     Generates the parameters for calling the mock function, accessing the private holder

     - parameters:
        - plainTypeName: the plain name of the type for which the dependency is being registered
        - arguments: the names of the arguments being passed to the mock function
     */
    static func generateMockFunctionCall(
        with plainTypeName: String,
        arguments: [String] = []
    ) -> String {
        let call = arguments.joined(separator: ", ")

        return "if let mock = \(plainTypeName)_MockHolder.mock { return mock(\(call)) }"
    }

    /**
     Extracts the type being registered for dependency injection

     Within the context of MDI, all registration macros receive as their first parameter the meta-type of the type being registered.
     `extractRegisteredType` expects the node received by the macro for expansion, and retrieves that same type.

     - note: The return object will be decorated the same way it was specified (e.g. with `any` or `some`)

     - parameter node: the received node
     - returns the type being registered, as specified by the first parameter of the macro
     */
    static func getRegisteredType(from node: AttributeSyntax) -> ExprSyntax? {
        node
            .arguments?
            .as(LabeledExprListSyntax.self)?
            .first?
            .as(LabeledExprSyntax.self)?
            .expression
            .as(MemberAccessExprSyntax.self)?
            .base
    }

    /**
     Extracts the factory expression used to create dependencies

     Within the context of MDI, all factory methods are passed as the last argument of the macro.
     `getFactoryExpression` retrieves this expression.

     - parameter node: the received node
     - returns the factory expression
     */
    static func getFactoryExpression(from node: AttributeSyntax) -> ExprSyntax? {
        node
            .arguments?
            .as(LabeledExprListSyntax.self)?
            .last?
            .as(LabeledExprSyntax.self)?
            .expression
    }

    /**
     Extracts the parameter types of the factory

     Within the context of MDI, whenever the factory's parameters are explicitly specifed,
     they fit between the return type and the factory.
     `getFactoryParameterTypes`

     - parameter node: the received node
     */
    static func getFactoryParameterTypes(from node: AttributeSyntax) -> [ExprSyntax] {
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

    static func getFactoryRegistrableParameterTypes(from node: AttributeSyntax) -> [(resolve: Bool, type: SyntaxProtocol)] {
        guard
            let types = node.arguments?.as(LabeledExprListSyntax.self)?.compactMap({ $0 }),
            types.count > 2
        else {
            return []
        }

        return types
            .inRange(1 ..< types.count - 1)
            .compactMap { type -> (Bool, SyntaxProtocol)? in
                guard
                    let enumerationItem = type.as(LabeledExprSyntax.self)?.expression.as(FunctionCallExprSyntax.self),
                    let caseName = enumerationItem.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text,
                    enumerationItem.arguments.count == 1,
                    let dependency = enumerationItem.arguments.first?.expression.as(MemberAccessExprSyntax.self)?.base
                else {
                    return nil
                }

                let resolve: Bool

                if caseName == "resolved" {
                    resolve = true
                } else if caseName == "explicit" {
                    resolve = false
                } else {
                    return nil
                }

                return (resolve, dependency)
            }
    }

    /**
     Extracts the plain type, removing `any` or `some` constraints
     */
    static func getPlainType(from syntax: SyntaxProtocol) -> SyntaxProtocol {
        if
            let tupple = syntax.as(TupleExprSyntax.self),
            tupple.elements.count == 1,
            let containedType = tupple.elements.first
        {
            return getPlainType(from: containedType)
        }

        if
            let constrainedType = syntax
                .as(LabeledExprSyntax.self)?
                .expression
                .as(TypeExprSyntax.self)?
                .type
                .as(SomeOrAnyTypeSyntax.self)?
                .constraint
        {
            return constrainedType
        }

        return syntax
    }

    /**
     Extracts the container name

     Within the context of MDI, all registrations are attached to a type declaration or extension.
     `extractContainerName` extracts the container name as a string.
     */
    static func getContainerName(from declaration: DeclGroupSyntax) -> String? {
        if let extendedType = declaration.as(ExtensionDeclSyntax.self)?.extendedType {
            return getPlainTypeName(from: extendedType)
        }

        return
            declaration.as(ClassDeclSyntax.self)?.name.text ??
            declaration.as(StructDeclSyntax.self)?.name.text ??
            declaration.as(EnumDeclSyntax.self)?.name.text ??
            declaration.as(ActorDeclSyntax.self)?.name.text
    }

    /**
     Get the plain name for a type, removing any trivia such as `any` or `some`
     */
    static func getPlainTypeName(from syntax: SyntaxProtocol) -> String? {
        if let identifier = syntax.as(IdentifierTypeSyntax.self) {
            return identifier.name.text
        }

        if let decl = syntax.as(DeclReferenceExprSyntax.self) {
            return decl.baseName.text
        }

        if let member = syntax.as(MemberAccessExprSyntax.self)?.base {
            return getPlainTypeName(from: member)
        }

        if let labeledExpression = syntax.as(LabeledExprSyntax.self)?.expression.as(TypeExprSyntax.self) {
            return getPlainTypeName(from: labeledExpression)
        }

        if let tuple = syntax.as(TupleExprSyntax.self) {
            if
                tuple.elements.count == 1,
                let containedType = tuple.elements.first
            {
                return getPlainTypeName(from: containedType)
            } else {
                return tuple.debugDescription
            }
        }

        if let someOrAnyType = syntax.as(TypeExprSyntax.self)?.type.as(SomeOrAnyTypeSyntax.self) {
            return getPlainTypeName(from: someOrAnyType.constraint)
        }

        return nil
    }
}
