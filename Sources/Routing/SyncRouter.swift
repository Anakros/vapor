import Async
import HTTP

/// Capable of registering sync routes.
public protocol SyncRouter: Router { }

extension SyncRouter {
    /// Registers a route handler at the supplied path.
    @discardableResult
    public func on(_ method: Method, to path: [PathComponent], use closure: @escaping BasicSyncResponder.Closure) -> Route {
        let responder = BasicSyncResponder(closure: closure)
        let route = Route(method: method, path: path, responder: responder)
        self.register(route: route)
        
        return route
    }
}

/// A basic, closure-based responder.
public struct BasicSyncResponder: Responder {
    /// Responder closure
    public typealias Closure = (Request) throws -> ResponseRepresentable
    
    /// The stored responder closure.
    public let closure: Closure

    /// Create a new basic responder.
    public init(closure: @escaping Closure) {
        self.closure = closure
    }

    /// See: HTTP.Responder.respond
    public func respond(to req: Request) throws -> Future<Response> {
        let res = try closure(req).makeResponse(for: req)
        let promise = Promise<Response>()
        promise.complete(res)
        return promise.future
    }
}

