import MDI
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MDIMacros)
import MDIMacros

let existencialTestMacros: [String: Macro.Type] = [
    "AutoRegister": DIAutoRegistration.self,
    "FactoryAutoRegister": DIFactoryAutoRegistration.self,
    "SingletonRegister": DISingletonRegistration.self
]
#endif

final class MDIExistencialTests: XCTestCase { }

// MARK: - SetUp / TearDown

extension MDIExistencialTests {
    override func setUp() {
        super.setUp()

        Self.mock((any AutoResolvedDependencyProtocol).self, factory: AutoResolvedDependencyMock.init)
        Self.mock((any FactoryResolvedDependencyProtocol).self, factory: FactoryResolvedDependencyMock.init)
        Self.mock((any SingletonResolvedDependencyProtocol).self, singleton: SingletonResolvedDependencyMock())
    }

    override func tearDown() {
        Self.mock((any AutoResolvedDependencyProtocol).self, factory: nil)
        Self.mock((any FactoryResolvedDependencyProtocol).self, factory: nil)
        Self.mock((any SingletonResolvedDependencyProtocol).self, singleton: nil)

        super.tearDown()
    }
}

// MARK: - Macro expansion tests

extension MDIExistencialTests {
    func testFactoryAutoRegister() throws {
#if canImport(MDIMacros)
        assertMacroExpansion(
                """
                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init(theme: any Theme, int: Int, _ session: String) { }
                }

                @FactoryAutoRegister((any TestProtocol).self, parameterTypes: .resolved((any Theme).self), .explicit(Int.self), .explicit(String.self), using: Test.init(theme:int:_:))
                extension Dependency {
                }
                """,
                expandedSource:
                """

                protocol TestProtocol {}
                struct Test: TestProtocol {
                    init(theme: any Theme, int: Int, _ session: String) { }
                }
                extension Dependency {

                    #if DEBUG
                    fileprivate enum TestProtocol_MockHolder {
                        static var mock: ((Int, String) -> (any TestProtocol))? = nil
                    }
                    #endif

                    static func mock(_: (any TestProtocol).Type, factory: ((Int, String) -> (any TestProtocol))?) {
                        #if DEBUG
                        TestProtocol_MockHolder.mock = factory
                        #endif
                    }

                    static func resolve(_: (any TestProtocol).Type, int: Int, _ arg0: String) -> (any TestProtocol) {
                        #if DEBUG
                        if let mock = TestProtocol_MockHolder.mock {
                            return mock(int, arg0)
                        }
                        #endif
                        return (Test.init(theme:int:_:))(Dependency.resolve((any Theme).self), int, arg0)
                    }

                    static func resolve(int: Int, _ arg0: String) -> (any TestProtocol) {
                        return (Test.init(theme:int:_:))(Dependency.resolve((any Theme).self), int, arg0)
                    }
                }
                """,
                macros: existencialTestMacros
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

                    #if DEBUG
                    fileprivate enum TestProtocol_MockHolder {
                        static var mock: (any TestProtocol)? = nil
                    }
                    #endif

                    static func mock(_: (any TestProtocol).Type, singleton: (any TestProtocol)?) {
                        #if DEBUG
                        TestProtocol_MockHolder.mock = singleton
                        #endif
                    }

                    fileprivate enum TestProtocol_Holder {
                        static let shared: (any TestProtocol) = {
                            (Test.init)()
                        }()
                    }

                    static func resolve(_: (any TestProtocol).Type) -> (any TestProtocol) {
                        #if DEBUG
                        if let mock = TestProtocol_MockHolder.mock {
                            return mock
                        }
                        #endif
                        return TestProtocol_Holder.shared
                    }

                    static func resolve() -> (any TestProtocol) {
                        return Self.resolve((any TestProtocol).self)
                    }
                }
                """,
                macros: existencialTestMacros
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

                @AutoRegister((any TestProtocol).self, parameterTypes: (any Nested).self, using: Test.init(nested:))
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

                    #if DEBUG
                    fileprivate enum TestProtocol_MockHolder {
                        static var mock: (() -> (any TestProtocol))? = nil
                    }
                    #endif

                    static func mock(_: (any TestProtocol).Type, factory: (() -> (any TestProtocol))?) {
                        #if DEBUG
                        TestProtocol_MockHolder.mock = factory
                        #endif
                    }

                    static func resolve(_: (any TestProtocol).Type) -> (any TestProtocol) {
                        #if DEBUG
                        if let mock = TestProtocol_MockHolder.mock {
                            return mock()
                        }
                        #endif
                        return (Test.init(nested:))(Dependency.resolve((any Nested).self))
                    }

                    static func resolve() -> (any TestProtocol) {
                        return resolve((any TestProtocol).self)
                    }
                }
                """,
                macros: existencialTestMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}

// MARK: - Mocking tests

extension MDIExistencialTests {
    func testMockTypeIsUsedForAutoRegisteredDependencyWhenRegistered() {
        XCTAssertEqual(Self.resolve((any AutoResolvedDependencyProtocol).self).name(), "AutoResolvedDependencyMock")
    }

    func testMockTypeIsUsedForSingletonRegisteredDependencyWhenRegistered() {
        XCTAssertEqual(Self.resolve((any SingletonResolvedDependencyProtocol).self).name(), "SingletonResolvedDependencyMock")
    }

    func testMockTypeIsUsedForFactoryRegisteredDependencyWhenRegistered() {
        XCTAssertEqual(Self.resolve((any FactoryResolvedDependencyProtocol).self).name(), "FactoryResolvedDependencyMock")
    }
}

// MARK: - Registration

@AutoRegister((any AutoResolvedDependencyProtocol).self, using: AutoResolvedDependencyImpl.init)
@FactoryRegister((any FactoryResolvedDependencyProtocol).self, using: FactoryResolvedDependencyImpl.init)
@SingletonRegister((any SingletonResolvedDependencyProtocol).self, using: SingletonResolvedDependencyImpl.init)
extension MDIExistencialTests { }
