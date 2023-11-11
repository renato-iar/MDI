/**
 Registers a dependency into the assembly, by auto-resolving all dependencies

 - parameters:
 - type: The type being registered into the assembly; typically a `protocol`. Will be the return type when calling `resolve`
 - parameterTypes: The types of each input necessary to execute the `factory`
 - factory: The factory to be used to resolve the dependency. Typically a `init` for some type conforming to the dependency type
 */
@attached(member, names: arbitrary)
public macro AutoRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat (each Parameter).Type,
    using factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIAutoRegistration")

/**
 Registers a dependency into the assembly as a singleton, by auto-resolving all dependencies

 - parameters:
 - type: The type being registered into the assembly; typically a `protocol`. Will be the return type when calling `resolve`
 - parameterTypes: The types of each input necessary to execute the `factory`
 - factory: The factory to be used to resolve the dependency. Typically a `init` for some type conforming to the dependency type
 */
@attached(member, names: arbitrary)
public macro SingletonRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat (each Parameter).Type,
    using factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DISingletonRegistration")

/**
 Registers a dependency into the assembly

 Non-resolvable dependencies (marked `.explicit(Dependency.self)`) are exposed, while resolvable dependencies (marked `.resolved(Dependency.self)`) are implicitly resolved
 Example:

 ```
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

 @FactoryRegister((any UserSession).self, parameterTypes: .resolved((any AppState).self), .explicit(String.self), with: UserSessionImpl.init(appState:sessionId:))
 class Dependency { }
 ```

 Will expose the following resolution method, exposing the non-resolvable parameter only, while auto resolving the resolvable dependency:

 ```
 ...
 class Dependency {
    static func resolve(_: (any UserSession).Type, sessionId: String) -> any UserSession {
        return (UserSessionImpl.init(appState:sessionId:))(Self.resolve(), sessionId)
    }
 }
 ```

 - parameters:
 - type: The type being registered into the assembly; typically a `protocol`. Will be the return type when calling `resolve`
 - parameterTypes: The types of each input necessary to execute the `factory`
 - factory: The factory to be used to resolve the dependency

 - note: `factory` might be a `init` for the concrete type, or a wrapper method, e.g. resolving all type dependencies via `resolve()` while exposing only non-resolvable parameters
 */
@available(*, deprecated, renamed: "Register", message: "Use @Register(_:parameterTypes:using:) instead")
@attached(member, names: arbitrary)
public macro FactoryRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat MDIFactoryDependency<each Parameter>,
    using factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIFactoryAutoRegistration")

/**
 Registers a dependency into the assembly

 Non-resolvable dependencies (marked `.explicit(Dependency.self)`) are exposed, while resolvable dependencies (marked `.resolved(Dependency.self)`) are implicitly resolved
 Example:

 ```
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

 @FactoryRegister((any UserSession).self, parameterTypes: .resolved((any AppState).self), .explicit(String.self), with: UserSessionImpl.init(appState:sessionId:))
 class Dependency { }
 ```

 Will expose the following resolution method, exposing the non-resolvable parameter only, while auto resolving the resolvable dependency:

 ```
 ...
 class Dependency {
    static func resolve(_: (any UserSession).Type, sessionId: String) -> any UserSession {
        return (UserSessionImpl.init(appState:sessionId:))(Self.resolve(), sessionId)
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
public macro Register<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat MDIFactoryDependency<each Parameter>,
    using factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIFactoryAutoRegistration")

/**
 Registers a dependency into the assembly

 All specified types are treated as dependencies that must be injected into the factory expression.
 For the previous example, using plain types:

 ```
 @FactoryRegister((any UserSession).self, parameterTypes: (any AppState).self, String.self, factory: UserSessionImpl.init(appState:sessionId:))
 class Dependency { }

 ```

 Will expose the following resolution method, exposing all parameters:

 ```
 class Dependency {
    static func resolve(_: (any UserSession).Type, appState: any AppState, sessionId: String) -> any UserSession {
        return (UserSessionImpl.init(appState:sessionId:))(appState, sessionId)
    }
 }
 ```

 - parameters:
 - type: The type being registered into the assembly; typically a `protocol`. Will be the return type when calling `resolve`
 - parameterTypes: The types of each input necessary to execute the `factory`
 - factory: The factory to be used to resolve the dependency

 - note: `factory` might be a `init` for the concrete type, or a wrapper method, e.g. resolving all type dependencies via `resolve()` while exposing only non-resolvable parameters
 */
@available(*, deprecated, renamed: "Register", message: "Use @Register(_:parameterTypes:factory:) instead")
@attached(member, names: arbitrary)
public macro FactoryRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat (each Parameter).Type,
    factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIFactoryAutoRegistration")

/**
 Registers a dependency into the assembly

 All specified types are treated as dependencies that must be injected into the factory expression.
 For the previous example, using plain types:

 ```
 @FactoryRegister((any UserSession).self, parameterTypes: (any AppState).self, String.self, factory: UserSessionImpl.init(appState:sessionId:))
 class Dependency { }

 ```

 Will expose the following resolution method, exposing all parameters:

 ```
 class Dependency {
    static func resolve(_: (any UserSession).Type, appState: any AppState, sessionId: String) -> any UserSession {
        return (UserSessionImpl.init(appState:sessionId:))(appState, sessionId)
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
public macro Factory<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat (each Parameter).Type,
    factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIFactoryAutoRegistration")
