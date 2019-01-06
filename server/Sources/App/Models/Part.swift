import Vapor
import FluentPostgreSQL

struct Part: PostgreSQLModel {
    var id: Int?
    var name: String
    var quantity: Int
    var statusID: Int
    var parentID: Int?
}

struct PartUpdate: Content {
    var name: String?
    var quantity: Int?
    var statusID: Int?
    var parentID: Int?
}

extension Part {
    var status: Parent<Part, Status> {
        return parent(\.statusID)
    }

    var subparts: Children<Part, Part> {
        return children(\.parentID)
    }
}

extension Part: Content {}

extension Part: Parameter {}

extension Part: PostgreSQLMigration {}
