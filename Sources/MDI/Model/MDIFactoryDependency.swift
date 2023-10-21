/**
 Annotate a parameter type as being resolvable by MDI
 */
public enum MDIFactoryDependency<T> {
    case resolved(T.Type)
    case explicit(T.Type)
}
