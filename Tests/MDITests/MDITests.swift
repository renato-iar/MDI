import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MDIMacros)
import MDIMacros

let testMacros: [String: Macro.Type] = [
    "AutoRegister": DIAutoRegistration.self,
    "FactoryRegister": DIFactoryRegistration.self,
    "SingletonRegister": DISingletonRegistration.self
]
#endif

final class MDITests: XCTestCase {
    func testFactoryRegister() throws {
#if canImport(MDIMacros)
        assertMacroExpansion(
                """
                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init(int: Int) { }
                }

                @FactoryRegister((any TestProtocol).self, parameterTypes: Int.self, factory: Test.init(int:))
                extension Dependency {
                }
                """,
                expandedSource:
                """

                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init(int: Int) { }
                }
                extension Dependency {

                    static func resolve(_: (any TestProtocol).Type, _ arg0: Int) -> (any TestProtocol) {
                        return (Test.init(int:))(arg0)
                    }

                    static func resolve(_ arg0: Int) -> (any TestProtocol) {
                        return (Test.init(int:))(arg0)
                    }
                }
                """,
                macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testSingletonRegister() throws {
#if canImport(MDIMacros)
        assertMacroExpansion(
                """
                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init() { }
                }

                @SingletonRegister((any TestProtocol).self, factory: Test.init)
                extension Dependency {
                }
                """,
                expandedSource:
                """

                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init() { }
                }
                extension Dependency {

                    static func resolve(_: (any TestProtocol).Type) -> (any TestProtocol) {
                        enum TestProtocol_Holder {
                            static let shared: (any TestProtocol) = {
                                (Test.init)()
                            }()
                        }
                        return TestProtocol_Holder.shared
                    }

                    static func resolve() -> (any TestProtocol) {
                        return Self.resolve((any TestProtocol).self)
                    }
                }
                """,
                macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif

    }

    func testAutoRegister() throws {
#if canImport(MDIMacros)
        assertMacroExpansion(
                """
                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init(nested: any Nested) { }
                }

                @AutoRegister((any TestProtocol).self, factory: Test.init(nested:))
                extension Dependency {
                }
                """,
                expandedSource:
                """

                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init(nested: any Nested) { }
                }
                extension Dependency {

                    static func resolve(_: (any TestProtocol).Type) -> (any TestProtocol) {
                        return (Test.init(nested:))(Self.resolve())
                    }

                    static func resolve() -> (any TestProtocol) {
                        return resolve((any TestProtocol).self)
                    }
                }
                """,
                macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
