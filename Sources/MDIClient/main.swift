import Foundation
import MDI

protocol Theme { }

struct ThemeImpl: Theme { }

protocol AppState { }

struct AppStateImpl: AppState {
    private let theme: Theme
    private let boot: Date
    private let version: String

    init(
        theme: Theme,
        boot date: Date,
        version: String
    ) {
        self.theme = theme
        self.boot = date
        self.version = version
    }

    static func factory(date: Date, version: String) -> Self {
        .init(
            theme: ExistencialDependency.resolve(Theme.self),
            boot: date,
            version: version
        )
    }
}

protocol ABTests { }
protocol CodeGuards { }
protocol ApplicationProxy { }

struct ABTestsImpl: ABTests { }
struct CodeGuardsImpl: CodeGuards { }
struct ApplicationProxyImpl: ApplicationProxy {
    init(
        abTests: ABTests,
        codeGuards: CodeGuards
    ) {
    }
}

// MARK: - Existencials

struct ExistencialDependency {
    static func resolve() -> String { " " }
    static func resolve() -> Double { 0 }
}

@FactoryRegister((any AppState).self, parameterTypes: .resolved((any Theme).self), .explicit(Date.self), .explicit(String.self), using: AppStateImpl.init(theme:boot:version:))
@SingletonRegister((any Theme).self, using: ThemeImpl.init)
@SingletonRegister((any ABTests).self, using: ABTestsImpl.init)
@SingletonRegister((any CodeGuards).self, using: CodeGuardsImpl.init)
@SingletonRegister((any ApplicationProxy).self, parameterTypes: (any ABTests).self, (any CodeGuards).self, using: ApplicationProxyImpl.init(abTests:codeGuards:))
extension ExistencialDependency { }

let existencialAppState: any AppState = ExistencialDependency.resolve(Date(), "1.0.0")
let existencialApplication: any ApplicationProxy = ExistencialDependency.resolve()

// MARK: - Opaque

struct OpaqueDependency {
    static func resolve() -> String { " " }
    static func resolve() -> Double { 0 }
}

@OpaqueFactoryRegister((any AppState).self, parameterTypes: .resolved((any Theme).self), .explicit(Date.self), .explicit(String.self), using: AppStateImpl.init(theme:boot:version:))
@OpaqueSingletonRegister((any Theme).self, using: ThemeImpl.init)
@OpaqueSingletonRegister((any ABTests).self, using: ABTestsImpl.init)
@OpaqueSingletonRegister((any CodeGuards).self, using: CodeGuardsImpl.init)
@OpaqueSingletonRegister((any ApplicationProxy).self, parameterTypes: (any ABTests).self, (any CodeGuards).self, using: ApplicationProxyImpl.init(abTests:codeGuards:))
extension OpaqueDependency { }

let opaqueAppState: some AppState = OpaqueDependency.resolve((any AppState).self, Date(), "1.0.0")
let opaqueApplication: some ApplicationProxy = OpaqueDependency.resolve((any ApplicationProxy).self)
