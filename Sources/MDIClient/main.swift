import Foundation
import MDI

protocol Theme { }

struct ThemeImpl: Theme { }

struct Dependency {
     static func resolve() -> String { " " }
     static func resolve() -> Double { 0 }
}

protocol AppState { }

struct AppStateImpl: AppState {
    private let theme: Theme
    private let boot: Date
    private let version: String

    private init(
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
            theme: Dependency.resolve(),
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

@FactoryRegister((any AppState).self, parameterTypes: Date.self, String.self, factory: AppStateImpl.factory(date:version:))
@SingletonRegister((any Theme).self, factory: ThemeImpl.init)
@AutoRegister((any ABTests).self, factory: ABTestsImpl.init)
@AutoRegister((any CodeGuards).self, factory: CodeGuardsImpl.init)
@SingletonRegister((any ApplicationProxy).self, factory: ApplicationProxyImpl.init(abTests:codeGuards:))
extension Dependency { }

let appState: AppState = Dependency.resolve(Date(), "1.0.0")
let application: ApplicationProxy = Dependency.resolve()
