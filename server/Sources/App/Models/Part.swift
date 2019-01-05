import Vapor
import FluentPostgreSQL

struct Part: PostgreSQLModel {
    var id: Int?
    var name: String
    var quantity: Int
    var statusID: Int
    var parentPartID: Int?
}

struct PartUpdate: Content {
    var name: String?
    var quantity: Int?
    var statusID: Int?
    var parentPartID: Int?
}

extension Part {
    var status: Parent<Part, Status> {
        return parent(\.statusID)
    }

    var subparts: Children<Part, Part> {
        return children(\.parentPartID)
    }
}

extension Part: Content {}

extension Part: Parameter {}

extension Part: Migration {}
