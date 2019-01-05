import Vapor
import FluentPostgreSQL

struct Status: PostgreSQLModel {
    var id: Int?
    var label: String
    var color: Int
}

struct StatusUpdate: Content {
    var label: String?
    var color: Int?
}
