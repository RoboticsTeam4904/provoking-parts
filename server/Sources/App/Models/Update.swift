import Vapor
import Fluent

struct Update<UpdateModel: AnyModel>: Content {
    var timestamp: DateTime
    var model: String

    var user: GoogleProfile?

    var old: UpdateModel?
    var new: UpdateModel?
}
