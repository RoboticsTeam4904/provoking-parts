import Vapor
import Fluent

/// Provides updates via REST long-polling.
final class UpdateController {
    func initialize(_ req: Request) throws -> Future<State> {
        return map(
            to: State.self,
            Part.query(on: req).all(),
            Status.query(on: req).all()) { parts, statuses, _ in
            return State(parts: parts, statuses: statuses)
        }
    }

    func handle(_ req: Request) throws -> EventStream {
        let updates = try req.make(UpdateService.self)
        return updates.stream(on: req)
    }
}
