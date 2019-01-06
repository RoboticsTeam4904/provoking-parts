import Vapor
import FluentPostgreSQL

struct GoogleProfile: PostgreSQLStringModel {
    var id: String?
    var name: String
    var givenName: String?
    var familyName: String?
    var picture: String
    var gender: String?
    var locale: String
}

extension GoogleProfile: Content {}

extension GoogleProfile: Parameter {}

extension GoogleProfile: PostgreSQLMigration {}
