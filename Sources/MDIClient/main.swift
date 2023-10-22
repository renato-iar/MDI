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

struct Dependency {
    static func resolve() -> String { " " }
    static func resolve() -> Double { 0 }
}

@FactoryRegister((any AppState).self, parameterTypes: .resolved((any Theme).self), .explicit(Date.self), .explicit(String.self), using: AppStateImpl.init(theme:boot:version:))
@OpaqueSingletonRegister((any Theme).self, using: ThemeImpl.init)
@OpaqueSingletonRegister((any ABTests).self, using: ABTestsImpl.init)
@OpaqueSingletonRegister((any CodeGuards).self, using: CodeGuardsImpl.init)
@OpaqueSingletonRegister((any ApplicationProxy).self, parameterTypes: (any ABTests).self, (any CodeGuards).self, using: ApplicationProxyImpl.init(abTests:codeGuards:))
extension Dependency { }

let existencialAppState: any AppState = Dependency.resolve(boot: Date(), version: "1.0.0")
let existencialApplication: any ApplicationProxy = Dependency.resolve(ApplicationProxy.self)
