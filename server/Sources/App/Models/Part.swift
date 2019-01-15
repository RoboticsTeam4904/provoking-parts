import Vapor
import FluentPostgreSQL

struct Part: PostgreSQLModel {
    var id: Int?
    var projectID: Int
    var statusID: Int
    var parentID: Int?
    var name: String
    var quantity: Int
}

struct PartUpdate: Content {
    var name: String?
    var projectID: Int?
    var statusID: Int?
    var parentID: Int?
    var quantity: Int?
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
