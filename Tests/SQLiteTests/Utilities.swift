import Async
import Dispatch
import XCTest
@testable import SQLite

extension SQLiteConnection {
    static func makeTestConnection(queue: DispatchQueue) -> SQLiteConnection? {
        do {
            let sqlite = SQLiteDatabase(
                storage: .file(path: "/tmp/test_database.sqlite")
            )
            return try sqlite.makeConnection(on: queue).blockingAwait()
        } catch {
            XCTFail()
        }
        return nil
    }
}
