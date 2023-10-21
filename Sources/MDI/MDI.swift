/**
 Registers a dependency into the assembly, by auto-resolving all dependencies

 - parameters:
    - type: The type being registered into the assembly; typically a `protocol`. Will be the return type when calling `resolve`
    - factory: The factory to be used to resolve the dependency. Typically a `init` for some type conforming to the dependency type
 */
@attached(member, names: arbitrary)
public macro AutoRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIAutoRegistration")

/**
 Registers a dependency into the assembly as a singleton, by auto-resolving all dependencies

 - parameters:
    - type: The type being registered into the assembly; typically a `protocol`. Will be the return type when calling `resolve`
    - factory: The factory to be used to resolve the dependency. Typically a `init` for some type conforming to the dependency type
 */
@attached(member, names: arbitrary)
public macro SingletonRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DISingletonRegistration")

/**
 Registers a dependency into the assembly, exposing all parameters required to build the concrete type

 - parameters:
    - type: The type being registered into the assembly; typically a `protocol`. Will be the return type when calling `resolve`
    - parameterTypes: The types of each input necessary to execute the `factory`
    - factory: The factory to be used to resolve the dependency

 - note: `factory` might be a `init` for the concrete type, or a wrapper method, e.g. resolving all type dependencies via `resolve()` while exposing only non-resolvable parameters
 */
@attached(member, names: arbitrary)
public macro FactoryRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat (each Parameter).Type,
    factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIFactoryRegistration")

/**
 Registers a dependency into the assembly

 Non-resolvable dependencies (marked `.explicit(Dependency.self)`) are exposed, while resolvable dependencies (marked `.resolved(Dependency.self)`) are implicitly resolved
 Example:

 ```swift
 protocol AppState {}
 protocol UserSession {}

 class AppStateImpl: AppState {
    init() {
    }
 }
 class UserSessionImpl: UserSession {
    init(
        appState: any AppState,
        sessionId: String
    ) {
        ...
    }
 }

 @AutoRegister((any AppState).self, factory: AppStateImpl.init)
 @FactoryRegister((any UserSession).self, parameterTypes: .resolved((any AppState).self), .explicit(String.self), with: UserSessionImpl.init)
 class Dependency { }
 ```

 Will expose the following resolution method, exposing the non-resolvable parameter only, while auto resolving the resolvable dependency:

 ```swift
 ...
 class Dependency {
    static func resolve(_: (any UserSession).Type, _ arg0: String) -> any UserSession {
        return (UserSessionImpl.init)(Self.resolve(), arg0)
    }
 }
 ```

 - parameters:
 - type: The type being registered into the assembly; typically a `protocol`. Will be the return type when calling `resolve`
 - parameterTypes: The types of each input necessary to execute the `factory`
 - factory: The factory to be used to resolve the dependency

 - note: `factory` might be a `init` for the concrete type, or a wrapper method, e.g. resolving all type dependencies via `resolve()` while exposing only non-resolvable parameters
 */
@attached(member, names: arbitrary)
public macro FactoryRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat MDIFactoryDependency<each Parameter>,
    using factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIFactoryAutoRegistration")
