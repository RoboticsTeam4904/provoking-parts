import Vapor

/// Controls basic CRUD operations on `Status`es.
final class StatusController {
    /// Returns a list of all `Status`es.
    func index(_ req: Request) throws -> Future<[Status]> {
        return Status.query(on: req).all()
    }

    /// Saves a decoded `Status` to the database.
    func create(_ req: Request) throws -> Future<Status> {
        let updates = try req.make(UpdateService.self)

        return try req.content.decode(Status.self).flatMap { data in
            // Copy immutable data and make it mutable.
            var status = data
            status.id = nil

            return status.save(on: req).flatMap { newStatus in
                try updates.update(
                    model: "Status", old: nil, new: newStatus, on: req)
            }
        }
    }

    /// Updates a parameterized `Status`.
    func update(_ req: Request) throws -> Future<Status> {
        let updates = try req.make(UpdateService.self)

        return try flatMap(to: Status.self,
            req.parameters.next(Status.self),
            req.content.decode(StatusUpdate.self)) { oldStatus, data in
                // Copy immutable status and make it mutable.
                var status = oldStatus

                if let label = data.label {
                    status.label = label
                }

                if let color = data.color {
                    status.color = color
                }

                return status.update(on: req).flatMap { newStatus in
                    try updates.update(
                        model: "Status", old: oldStatus, new: newStatus, on: req)
                }
        }
    }

    /// Deletes a parameterized `Status`.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let updates = try req.make(UpdateService.self)

        return try req.parameters.next(Status.self).flatMap { oldStatus in
            oldStatus.delete(on: req).flatMap { _ in
                try updates.update(
                    model: "Status", old: oldStatus, new: nil, on: req)
            }
        }.transform(to: .ok)
    }
}
