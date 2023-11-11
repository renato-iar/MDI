import MDI
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MDIMacros)
import MDIMacros

let opaqueTestMacros: [String: Macro.Type] = [
    "OpaqueAutoRegister": DIOpaqueAutoRegistration.self,
    "OpaqueFactoryRegister": DIOpaqueFactoryRegistration.self,
    "OpaqueSingletonRegister": DIOpaqueSingletonRegistration.self
]
#endif

final class MDIOpaqueTests: XCTestCase { }

// MARK: - Macro expansion tests

extension MDIOpaqueTests {
    func testFactoryRegister() throws {
#if canImport(MDIMacros)
        assertMacroExpansion(
                """
                @OpaqueFactoryRegister((any TestProtocol).self, parameterTypes: .resolved((any Theme).self), .explicit(Int.self), using: Test.init(theme:int:))
                extension Dependency {
                }
                """,
                expandedSource:
                """

                extension Dependency {

                    static func resolve(_: (any TestProtocol).Type, int: Int) -> some TestProtocol {
                        return (Test.init(theme:int:))(Dependency.resolve((any Theme).self), int)
                    }

                    struct TestProtocolFactory {
                        fileprivate init() {
                        }

                        public func make(int: Int) -> some TestProtocol {
                            return Dependency.resolve((any TestProtocol).self, int: int)
                        }
                    }

                    static func factory(of: (any TestProtocol).Type) -> TestProtocolFactory {
                        return TestProtocolFactory()
                    }

                    static func factory(of: (any TestProtocol).Type, int: Int) -> MDIFactory<some TestProtocol> {
                        return MDIFactory {
                            Dependency.resolve((any TestProtocol).self, int: int)
                        }
                    }
                }
                """,
                macros: opaqueTestMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testFactoryAutoRegisterWithFullExplicitTypes() throws {
#if canImport(MDIMacros)
        assertMacroExpansion(
                """
                @OpaqueFactoryRegister((any AppState).self, parameterTypes: Date.self, String.self, factory: AppStateImpl.factory(boot:version:))
                extension Dependency {
                }
                """,
                expandedSource:
                """

                extension Dependency {

                    static func resolve(_: (any AppState).Type, boot: Date, version: String) -> some AppState {
                        return (AppStateImpl.factory(boot:version:))(boot, version)
                    }

                    struct AppStateFactory {
                        fileprivate init() {
                        }

                        public func make(boot: Date, version: String) -> some AppState {
                            return Dependency.resolve((any AppState).self, boot: boot, version: version)
                        }
                    }

                    static func factory(of: (any AppState).Type) -> AppStateFactory {
                        return AppStateFactory()
                    }

                    static func factory(of: (any AppState).Type, boot: Date, version: String) -> MDIFactory<some AppState> {
                        return MDIFactory {
                            Dependency.resolve((any AppState).self, boot: boot, version: version)
                        }
                    }
                }
                """,
                macros: opaqueTestMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testSingletonRegister() throws {
#if canImport(MDIMacros)
        assertMacroExpansion(
                """
                @OpaqueSingletonRegister((any TestProtocol).self, factory: Test.init)
                extension Dependency {
                }
                """,
                expandedSource:
                """

                extension Dependency {

                    fileprivate enum TestProtocol_Holder {
                        static let shared: some TestProtocol = (Test.init)()
                    }

                    static func resolve(_: (any TestProtocol).Type) -> some TestProtocol {
                        return TestProtocol_Holder.shared
                    }
                }
                """,
                macros: opaqueTestMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif

    }

    func testAutoRegister() throws {
#if canImport(MDIMacros)
        assertMacroExpansion(
                """
                @OpaqueAutoRegister((any TestProtocol).self, parameterTypes: (any Nested).self, factory: Test.init(nested:))
                extension Dependency {
                }
                """,
                expandedSource:
                """

                extension Dependency {

                    static func resolve(_: (any TestProtocol).Type) -> some TestProtocol {
                        return (Test.init(nested:))(Self.resolve((any Nested).self))
                    }

                    static func factory(of _: (any TestProtocol).Type) -> MDIFactory<some TestProtocol> {
                        return MDIFactory {
                            return resolve((any TestProtocol).self)
                        }
                    }
                }
                """,
                macros: opaqueTestMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
