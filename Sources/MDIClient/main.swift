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

@Register((any AppState).self, parameterTypes: .resolved((any Theme).self), .explicit(Date.self), .explicit(String.self), using: AppStateImpl.init(theme:boot:version:))
@Register((any Theme).self, using: ThemeImpl.init)
@OpaqueSingletonRegister((any ABTests).self, using: ABTestsImpl.init)
@OpaqueSingletonRegister((any CodeGuards).self, using: CodeGuardsImpl.init)
@OpaqueSingletonRegister((any ApplicationProxy).self, parameterTypes: (any ABTests).self, (any CodeGuards).self, using: ApplicationProxyImpl.init(abTests:codeGuards:))
extension Dependency { }

let forwardingAppStateFactory = Dependency.factory(of: AppState.self, boot: Date(), version: "1.0.1")
let appState = forwardingAppStateFactory.make()

let opaqueAppStateFactory = Dependency.factory(of: AppState.self)
let opaqueAppState = opaqueAppStateFactory.make(boot: Date(), version: "1.0.0")
let application: any ApplicationProxy = Dependency.resolve(ApplicationProxy.self)
