import Vapor
import FluentPostgreSQL

struct Project: PostgreSQLModel {
    var id: Int?
    var name: String
}

struct ProjectUpdate: Content {
    var name: String?
}

extension Project {
    var parts: Children<Project, Part> {
        return children(\.projectID)
    }
}

extension Project: Content {}

extension Project: Parameter {}

extension Project: PostgreSQLMigration {}
