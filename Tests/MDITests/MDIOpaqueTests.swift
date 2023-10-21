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
                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init(theme: any Theme, int: Int) { }
                }

                @OpaqueFactoryRegister((any TestProtocol).self, parameterTypes: .resolved((any Theme).self), .explicit(Int.self), using: Test.init(theme:int:))
                extension Dependency {
                }
                """,
                expandedSource:
                """

                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init(theme: any Theme, int: Int) { }
                }
                extension Dependency {

                    static func resolve(_: (any TestProtocol).Type, _ arg0: Int) -> some TestProtocol {
                        return (Test.init(theme:int:))(Self.resolve((any Theme).self), arg0)
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
                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init() { }
                }

                @OpaqueSingletonRegister((any TestProtocol).self, factory: Test.init)
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
                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init(nested: any Nested) { }
                }

                @OpaqueAutoRegister((any TestProtocol).self, parameterTypes: (any Nested).self, factory: Test.init(nested:))
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

                    static func resolve(_: (any TestProtocol).Type) -> some TestProtocol {
                        return (Test.init(nested:))(Self.resolve((any Nested).self))
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
