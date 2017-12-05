import Async
import Dispatch
import Fluent
import Foundation

extension Benchmarker where Database.Connection: TransactionSupporting {
    /// The actual benchmark.
    fileprivate func _benchmark(on conn: Database.Connection) throws -> Future<Void> {
        // create
        let tanner = User<Database>(name: "Tanner", age: 23)
        let promise = Promise<Void>()
        
        tanner.save(on: conn).then {
            return conn.transaction { conn in
                var future = Future<Void>(())
                
                /// create 100 users
                for i in 1...100 {
                    let user = User<Database>(name: "User \(i)", age: i)
                    
                    future = future.then { _ -> Future<Void> in
                        return user.save(on: conn)
                    }
                }
                
                return future.then {
                    // count users
                    return conn.query(User<Database>.self).count().then { count -> Future<Void> in
                        if count != 101 {
                            self.fail("count should be 101")
                        }
                        
                        throw "rollback"
                    }
                }
            }
        }.addAwaiter { result in
            if result.error == nil {
                self.fail("transaction must fail")
            }
            
            promise.complete()
        }
        
        return promise.future.then { () -> Future<Int> in
            return conn.query(User<Database>.self).count()
        }.map { count in
            guard count == 1 else {
                self.fail("count must have been restored to one")
                return
            }
        }
    }

    /// Benchmark fluent transactions.
    public func benchmarkTransactions() throws -> Future<Void> {
        return pool.requestConnection().then { conn in
            return try self._benchmark(on: conn).map {
                self.pool.releaseConnection(conn)
            }
        }
    }
}

extension Benchmarker where Database.Connection: TransactionSupporting & SchemaSupporting {
    /// Benchmark fluent transactions.
    /// The schema will be prepared first.
    public func benchmarkTransactions_withSchema() throws -> Future<Void> {
        return pool.requestConnection().then { conn in
            return UserMigration<Database>.prepare(on: conn).then {
                return try self._benchmark(on: conn).map {
                    self.pool.releaseConnection(conn)
                }
            }
        }
    }
}


