import MDI
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

final class MDITests: XCTestCase { }

// MARK: - SetUp / TearDown

extension MDITests {
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

extension MDITests {
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

                    #if DEBUG
                    fileprivate enum TestProtocol_MockHolder {
                        static var mock: ((Int) -> (any TestProtocol))? = nil
                    }
                    #endif

                    static func mock(_: (any TestProtocol).Type, factory: ((Int) -> (any TestProtocol))?) {
                        #if DEBUG
                        TestProtocol_MockHolder.mock = factory
                        #endif
                    }

                    static func resolve(_: (any TestProtocol).Type, _ arg0: Int) -> (any TestProtocol) {
                        #if DEBUG
                        if let mock = TestProtocol_MockHolder.mock {
                            return mock(arg0)
                        }
                        #endif
                        return (Test.init(int:))(arg0)
                    }

                    static func resolve(_ arg0: Int) -> (any TestProtocol) {
                        return resolve((any TestProtocol).self, arg0)
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

// MARK: - Mocking tests

extension MDITests {
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

@AutoRegister((any AutoResolvedDependencyProtocol).self, factory: AutoResolvedDependencyImpl.init)
@FactoryRegister((any FactoryResolvedDependencyProtocol).self, factory: FactoryResolvedDependencyImpl.init)
@SingletonRegister((any SingletonResolvedDependencyProtocol).self, factory: SingletonResolvedDependencyImpl.init)
extension MDITests { }
