public struct MDIFactory<Output> {

    private let factory: () -> Output

    public init<each Parameter>(
        parameter: repeat each Parameter,
        factory f: @escaping (repeat each Parameter) -> Output
    ) {
        self.factory = {
            f(repeat each parameter)
        }
    }

    public func make() -> Output {
        factory()
    }
}
