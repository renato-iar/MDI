/**
 Registers a dependency into the assembly as an opaque type, by auto-resolving all dependencies

 - parameters:
    - type: The type being registered into the assembly; typically a `protocol`. Will be the return type when calling `resolve`
    - parameterTypes: The types of the dependencies passed to the factory; `resolve` will be called on each of them when the factory is executed
    - factory: The factory to be used to resolve the dependency. Typically a `init` for some type conforming to the dependency type
 */
@attached(member, names: arbitrary)
public macro OpaqueAutoRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat (each Parameter).Type,
    using factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIOpaqueAutoRegistration")

/**
 Registers a dependency into the assembly as a singleton, by auto-resolving all dependencies

 - parameters:
    - type: The type being registered into the assembly; typically a `protocol`. Will be the return type when calling `resolve`
    - parameterTypes: The types of the dependencies passed to the factory; `resolve` will be called on each of them when the factory is executed
    - factory: The factory to be used to resolve the dependency. Typically a `init` for some type conforming to the dependency type
 */
@attached(member, names: arbitrary)
public macro OpaqueSingletonRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat (each Parameter).Type,
    using factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIOpaqueSingletonRegistration")

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
@available(*, deprecated, renamed: "OpaqueRegister(_:parameterTypes:using:)", message: "Use @OpaqueRegister(_:parameterTypes:using:) instead")
@attached(member, names: arbitrary)
public macro OpaqueFactoryRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat MDIFactoryDependency<each Parameter>,
    using factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIOpaqueFactoryRegistration")

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
public macro OpaqueRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat MDIFactoryDependency<each Parameter>,
    using factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIOpaqueFactoryRegistration")

/**
 Registers a dependency into the assembly

 All specified types are treated as dependencies that must be injected into the factory expression.
 For the previous example, using plain types:

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

 @FactoryRegister((any UserSession).self, parameterTypes: (any AppState).self, String.self, with: UserSessionImpl.init(appState:sessionId))
 class Dependency { }
 ```

 Will expose the following resolution method, exposing all dependencies:

 ```swift
 ...
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
@available(*, deprecated, renamed: "OpaqueRegister(_:paramterTypes:factory:)", message: "Use @OpaqueRegister(_:parameterTypes:factory:) instead")
@attached(member, names: arbitrary)
public macro OpaqueFactoryRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat (each Parameter).Type,
    factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIOpaqueFactoryRegistration")

/**
 Registers a dependency into the assembly

 All specified types are treated as dependencies that must be injected into the factory expression.
 For the previous example, using plain types:

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

 @FactoryRegister((any UserSession).self, parameterTypes: (any AppState).self, String.self, with: UserSessionImpl.init(appState:sessionId))
 class Dependency { }
 ```

 Will expose the following resolution method, exposing all dependencies:

 ```swift
 ...
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
public macro OpaqueRegister<each Parameter, ResolvedType>(
    _ type: ResolvedType.Type,
    parameterTypes: repeat (each Parameter).Type,
    factory: (repeat each Parameter) -> ResolvedType
) = #externalMacro(module: "MDIMacros", type: "DIOpaqueFactoryRegistration")
