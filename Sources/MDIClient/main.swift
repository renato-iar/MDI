import Foundation
import MDI

protocol Animal { }

struct Cat: Animal {
    let name: String

    init(name: String) {
        self.name = name
    }

    init() {
        self.init(name: "Luna")
    }
}

protocol Virus { }

struct SARSCov19: Virus { }

protocol SickAnimal { }

struct SickAnimalImpl: SickAnimal {
    let animal: Animal
    let virus: Virus

    init(animal: Animal, virus: Virus) {
        self.animal = animal
        self.virus = virus
    }
}

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

@FactoryRegister((any AppState).self, parameterTypes: Date.self, String.self, factory: AppStateImpl.factory(date:version:))
@SingletonRegister((any Theme).self, factory: ThemeImpl.init)
@AutoRegister((any Virus).self, factory: SARSCov19.init)
@AutoRegister((any Animal).self, factory: Cat.init(name:))
@AutoRegister((any SickAnimal).self, factory: SickAnimalImpl.init(animal:virus:))
extension Dependency { }

let appState: AppState = Dependency.resolve(Date(), "1.0.0")
let theme: Theme = Dependency.resolve()
let sickAnimal: SickAnimal = Dependency.resolve()
