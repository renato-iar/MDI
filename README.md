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

## Example Usage

Define some type that will serve both as the "assembly hub" and the resolution entry point.
An empty `enum` should be enough.

```
enum Dependency { }
```

On this example, assemblies will be defined in extensions of `Dependency` (although this is not mandatory and can be done directly on the type declaration).
In the following example, we will assume the following types:

```
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

```
import MDI

@SingletonRegister((any ABTestingProtocol).self, factory: ABTesting.init)
@SingletonRegister((any CodeGuardsProtocol).self, factory: CodeGuards.init)
@SingletonRegister((any ThemeProtocol).self, factory: Theme.init(abTesting:codeGuards:))
extension Dependency { }
```

`@SingletonRegister` will call `resolve` on both `ABTestingProtocol` and `CodeGuardsProtocol`.
Since both are declared in the assembly (mind they could easily be declared elsewhere) this succeeds; otherwise we'd get a compiler error.
Note that, in the previous example, all dependencies were singletons, but this obviously did not have to be the case.

If instead `@AutoRegister` was used:

```
import MDI

@AutoRegister((any ABTestingProtocol).self, factory: ABTesting.init)
@AutoRegister((any CodeGuardsProtocol).self, factory: CodeGuards.init)
@AutoRegister((any ThemeProtocol).self, factory: Theme.init(abTesting:codeGuards:))
extension Dependency { }
```

New instances of the registered types would be created on each call to `resolve(...)`.

Finally, some dependencies require parameters that cannot be resolved, but rather passed when instancing.
This can easily be achieved via `@FactoryRegister`.
In the following example, we can resolve `ThemeProtocol`, but not necessarily `boot: Date` or `sessionId: String`.

```
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

```
import MDI

private extension AppContext {
    static func factory(
        boot: Date,
        sessionId: String
    ) -> AppContext {
        return AppContext(
            boot: boot,
            sessionId: sessionId,
            theme: Dependency.resolve()
        )
    }
}

@FactoryRegister(
    (any AppContextProtocol).self,
    parameterTypes: Date.self, String.self,
    factory: AppContext.factory(boot:sessionId:)
)
extension Dependency { }
```

Using this approach, `Dependency` will expose a `resolve` method typed:
```
Dependency.resolve(_ arg1: Date, _ arg1: String) -> any AppContextProtocol
``````

## Installation

### Swift Package Manager

You can use the Swift Package Manager to install your package by adding it as a dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "git@github.com:renato-iar/MDI.git", from: "1.0.0")
]
