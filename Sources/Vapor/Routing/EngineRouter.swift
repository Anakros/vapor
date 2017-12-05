import Routing
import Bits

/// An HTTP wrapper around the TrieNodeRouter
public final class EngineRouter: Router {
    /// The internal router
    private let router: TrieRouter<Responder>

    /// See Router.routes
    public var routes: [Route<Responder>] {
        return router.routes
    }

    /// Create a new engine router
    public init() {
        self.router = .init()
    }

    /// Create a new engine router with default settings.
    public static func `default`() -> EngineRouter {
        let router = EngineRouter()
        router.router.fallback = BasicResponder { req in
            let res = req.makeResponse()
            res.http.status = .notFound
            res.http.body = HTTPBody(string: "Not found")
            return Future(res)
        }
        return router
    }

    /// See Router.register
    public func register(route: Route<Responder>) {
        router.register(route: route)
    }
    
    /// Splits the URI into a substring for each component
    fileprivate func withPathComponents<T>(for request: Request, do closure: ([PathComponent.Parameter]) -> T) -> T {
        return request.http.uri.pathBytes.withUnsafeBufferPointer { (uri: ByteBuffer) in
            var array = [PathComponent.Parameter]()
            array.reserveCapacity(8)

            var baseIndex = uri.startIndex
            if uri[0] == .forwardSlash {
                // Skip past the first `/`
                baseIndex = uri.index(after: uri.startIndex)
            }
            
            if baseIndex < uri.endIndex {
                var currentIndex = baseIndex
                
                // Split up the path
                while currentIndex < uri.endIndex {
                    if uri[currentIndex] == .forwardSlash {
                        array.append(.byteBuffer(
                            ByteBuffer(start: uri.baseAddress?.advanced(by: baseIndex), count: currentIndex - baseIndex)
                        ))
                        
                        baseIndex = uri.index(after: currentIndex)
                        currentIndex = baseIndex
                    } else {
                        currentIndex = uri.index(after: currentIndex)
                    }
                }
                
                // Add remaining path component
                if baseIndex != uri.endIndex {
                    array.append(.byteBuffer(
                        ByteBuffer(start: uri.baseAddress?.advanced(by: baseIndex), count: uri.endIndex - baseIndex)
                    ))
                }
            }
            
            return closure(array)
        }
    }

    /// See Router.route
    public func route(request: Request) -> Responder? {
        return withPathComponents(for: request) { components in
            return router.route(path: [
                .bytes(request.http.method.bytes)
            ] + components, parameters: request)
        }
    }
}
