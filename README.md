# MDI
Zero-cost dependency injection using Swift Macros

## Features

- Implements zero-cost dependency injection via Swift Macros
  - `@AutoRegister` calls `resolve()` on all the factory's dependencies
  - `@SingletonRegister` follows the same principle as `@AutoRegister`, but storing (and exposing) the generated value in a singleton
  - `@FactoryRegister` exposes all parameters to the `resolve(...)` method
- Type safe
- Generates vanilla Swift

## Requirements

- Requires Swift 5.9

## Limitations

Presently, the following limitations exist (due to compiler bug):

- The hub type used to register dependencies must either be a `class` or a `struct`; using `enum`s will result in the compiler failing
- All dependencies must be registered in the same file where the hub type is declared (they can be split into multiple `extension`s for organization though)

# Versions

## Version 4.1.0

- Restores factory for "naked" types, treating all stated dependencies as explicit.

## Version 4.0.0

- Fully deprecates `@FactoryRegister(_:parameterTypes:factory:)` in favour of `@FactoryRegister(_:parameterTypes:using:)` (which allows mixing explict parameters with auto-resolved dependencies)
- Adopts named parameters when it is possible to retrieve them from the factory definition (e.g. when a method name is used such as `SomeTime.init(resolvableDependencyA:resolvableDependencyB:parameter1:parameter2)`)

## Version 3.0.0

- Add full support for registered opaque types to interplay with non-opaque registrations
- Soft deprecation of `@FactoryRegister(_:parameterTypes:factory:)`

## Version 2.2.0

- Adds support for registering dependencies into the assembly using opaque types

## Version 2.1.0

- Allows factories to be registered using mixed types: auto-resolved and parametric

## Version 2.0.2

- Remove sample client from products

## Version 2.0.1

- Fix `getPlainTypeName`, which was failing to extract simple types

## Version 2.0.0

- Improve mock functions to take parameters in factories

## Version 1.1.0

- Add mocking

## Example Usage

### Plain types & existencials

Define some type that will serve both as the "assembly hub" and the resolution entry point.
(As stated in Limitations, `enum`s are not supported).

```swift
enum Dependency { }
```

On this example, assemblies will be defined in extensions of `Dependency` (although this is not mandatory and can be done directly on the type declaration).
In the following example, we will assume the following types:

```swift
protocol ABTestingProtocol { }
protocol CodeGuardsProtocol { }
protocol ThemeProtocol { }

final class ABTesting: ABTestingProtocol { }
final class CodeGuards: CodeGuardsProtocol { }
final class Theme: ThemeProtocol {
    private let abTesting: ABTestingProtocol
    private let codeGuards: CodeGuardsProtocol

    init(
        abTesting: ABTestingProtocol,
        codeGuards: CodeGuardsProtocol
    ) {
        self.abTesting = abTesting
        self.codeGuards = codeGuards
    }
}
```

And then create an assembly to register them:

```swift
import MDI

@SingletonRegister((any ABTestingProtocol).self, using: ABTesting.init)
@SingletonRegister((any CodeGuardsProtocol).self, using: CodeGuards.init)
@SingletonRegister((any ThemeProtocol).self, parameterTypes: (any ABTestingProtocol).self, (any CodeGuardsProtocol).self, using: Theme.init(abTesting:codeGuards:))
extension Dependency { }
```

`@SingletonRegister` will call `resolve` on both `ABTestingProtocol` and `CodeGuardsProtocol`.
Since both are declared in the assembly (mind they could easily be declared elsewhere) this succeeds; otherwise we'd get a compiler error.
Note that, in the previous example, all dependencies were singletons, but this obviously did not have to be the case.

If instead `@AutoRegister` was used:

```swift
import MDI

@AutoRegister((any ABTestingProtocol).self, using: ABTesting.init)
@AutoRegister((any CodeGuardsProtocol).self, using: CodeGuards.init)
@AutoRegister((any ThemeProtocol).self, parameterTypes: (any ABTestingProtocol).self, (any CodeGuardsProtocol).self, using: Theme.init(abTesting:codeGuards:))
extension Dependency { }
```

New instances of the registered types would be created on each call to `resolve(...)`.

Finally, some dependencies require parameters that cannot be resolved, but rather passed when instancing.
This can easily be achieved via `@FactoryRegister`.
In the following example, we can resolve `ThemeProtocol`, but not necessarily `boot: Date` or `sessionId: String`.

```swift
protocol AppContextProtocol {}

final class AppContext: AppContextProtocol {
    let boot: Date
    let sessionId: String
    let theme: ThemeProtocol

    init(
        boot: Date,
        sessionId: String,
        theme: ThemeProtocol
    ) {
        self.boot = boot
        self.sessionId = sessionId
        self.theme = theme
    }
}
```

Using `@FactoryRegister` we can expose the required parameters while even leveraging `resolve(...)` in the factory method to resolve `ThemeProtocol`:

```swift
import MDI

@FactoryRegister(
    (any AppContextProtocol).self,
    parameterTypes: .explicit(Date.self), .explicit(String.self), .resolved((any Theme).self),
    using: AppContext.init(boot:sessionId:theme:)
)
extension Dependency { }
```

This will expose a `resolve` method that exposes `Date` and `String` while  implicitly resolving `Theme`.

```swift
extension Dependency {
    static func resolve(_: any AppContextProtocol, boot: Date, sessionId: String) -> any AppContextProtocol {
        return (AppContextProtocolImpl.init(boot:sessionId:theme:))(boot, sessionId, Self.resolve())
    }
}
```

### Opaque types

Variants for the previous macros exist, supporting opaque types:

- `@OpaqueAutoRegister` is equivalent to `@AutoRegister`
- `@OpaqueSingletonRegister` is equivalent to `@SingletonRegister`
- `@OpaqueFactoryRegister` is equivalent to `@FactoryRegister`

The main differences being:

- All macros expect explicit typing of the factory's parameters through `parameterTypes`; these will be used to univoquely resolve types
- The factory used to create the instance must resolve into a concrete type, or to an opaque type itself

## Installation

### Swift Package Manager

You can use the Swift Package Manager to install your package by adding it as a dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "git@github.com:renato-iar/MDI.git", from: "1.0.0")
]
