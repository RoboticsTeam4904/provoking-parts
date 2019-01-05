import Vapor

struct State: Content {
    var parts: [Part]
    var statuses: [Status]
}
