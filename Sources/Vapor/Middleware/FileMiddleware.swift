import libc
import HTTP
import Bits
import Core
import Foundation
import Dispatch

/// Services files from the public folder.
public final class FileMiddleware: Middleware {
    /// The public directory.
    /// note: does _not_ end with a slash
    let publicDirectory: String
    
    public var webTypes = [MediaType]()

    /// Creates a new filemiddleware.
    public init(publicDirectory: String) {
        self.publicDirectory = publicDirectory.finished(with: "/")
    }

    /// See Middleware.respond.
    public func respond(to req: Request, chainingTo next: Responder) throws -> Future<Response> {
        let reader = try req.eventLoop.make(FileReader.self, for: FileMiddleware.self)
        
        var path = req.http.uri.path
        if path.hasPrefix("/") {
            path = String(path.dropFirst())
        }
        guard !path.contains("../") else {
            throw Abort(.forbidden)
        }
        
        let filePath = self.publicDirectory + path
        
        guard reader.fileExists(at: filePath) else {
            return try next.respond(to: req)
        }
        
        return Future(try req.streamFile(at: filePath))
    }
}
