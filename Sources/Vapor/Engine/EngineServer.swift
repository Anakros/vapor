import Async
import Console
import Core
import Debugging
import Dispatch
import Foundation
import HTTP
import ServerSecurity
import Service
import TCP

/// A TCP based server with HTTP parsing and serialization pipeline.
public final class EngineServer: Server {
    /// Chosen configuration for this server.
    public let config: EngineServerConfig

    /// Container for setting on event loops.
    public let container: Container

    /// Create a new EngineServer using config struct.
    public init(
        config: EngineServerConfig,
        container: Container
    ) {
        self.config = config
        self.container = container
    }

    /// Start the server. Server protocol requirement.
    public func start(with responder: Responder) throws {
        var eventLoops: [Container] = []
        for i in 0..<config.workerCount {
            // create new event loop
            let queue = DispatchQueue(label: "codes.vapor.engine.server.worker.\(i)")

            // copy services into new container
            let eventLoop = self.container.makeSubContainer(on: queue)
            eventLoops.append(eventLoop)
        }
        var eventLoopsIterator = LoopIterator<[Container]>(collection: eventLoops)

        // create a tcp server
        let tcp = try TCPServer(eventLoops: eventLoops.map { $0.queue })

        tcp.willAccept = PeerValidator(maxConnectionsPerIP: config.maxConnectionsPerIP).willAccept
        let server = HTTPServer(socket: tcp)

        let console = try container.make(Console.self, for: EngineServer.self)
        let logger = try container.make(Logger.self, for: EngineServer.self)
        
        // setup the server pipeline
        server.drain { client in
            let eventLoop = eventLoopsIterator.next()!
            let parser = HTTP.RequestParser(maxSize: 10_000_000)
            let responderStream = ResponderStream(
                responder: responder,
                using: eventLoop
            )
            let serializer = HTTP.ResponseSerializer()
            
            client.stream(to: parser)
                .stream(to: responderStream)
                .stream(to: serializer)
                .drain { data in
                    client.onInput(data)
                    serializer.upgradeHandler?.closure(client.tcp)
                }.catch { error in
                    logger.reportError(error, as: "Uncaught error")
                    client.close()
                }

            client.tcp.start()
        }.catch { err in
            logger.reportError(err, as: "Server error")
            debugPrint(err)
        }
        
        console.print("Server starting on ", newLine: false)
        console.output("http://" + config.hostname, style: .custom(.cyan), newLine: false)
        console.output(":" + config.port.description, style: .custom(.cyan))

        // bind, listen, and start accepting
        try tcp.start(
            hostname: config.hostname,
            port: config.port,
            backlog: config.backlog
        )

        // non-blocking main thread run
        RunLoop.main.run()
    }
}

extension Logger {
    fileprivate func reportError(_ error: Error, as label: String) {
        var string = "\(label): "
        if let debuggable = error as? Debuggable {
            string += debuggable.fullIdentifier
            string += ": "
            string += debuggable.reason
        } else {
            string += "\(error)"
        }
        if let traceable = error as? Traceable {
            self.error(string,
                file: traceable.file,
                function: traceable.function,
                line: traceable.line,
                column: traceable.column
            )
        } else {
            self.error(string)
        }
    }
}

/// Engine server config struct.
public struct EngineServerConfig {
    /// Host name the server will bind to.
    public let hostname: String

    /// Port the server will bind to.
    public let port: UInt16

    /// Listen backlog.
    public let backlog: Int32

    /// Number of client accepting workers.
    /// Should be equal to the number of logical cores.
    public let workerCount: Int
    
    /// Limits the amount of connections per IP address to prevent certain Denial of Service attacks
    public let maxConnectionsPerIP: Int

    /// Creates a new engine server config
    public init(
        hostname: String = "localhost",
        port: UInt16 = 8080,
        backlog: Int32 = 4096,
        workerCount: Int = 8,
        maxConnectionsPerIP: Int = 128
    ) {
        self.hostname = hostname
        self.port = port
        self.backlog = backlog
        self.workerCount = workerCount
        self.maxConnectionsPerIP = maxConnectionsPerIP
    }
}
