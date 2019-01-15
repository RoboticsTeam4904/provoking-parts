import Vapor
import Imperial

public func routes(_ router: Router) throws {
    try router.oAuth(
        from: Google.self,
        authenticate: "google",
        callback: "http://parts.botprovoking.org/callback/google",
        scope: ["profile"]) { (req, token) in

        let url = URL(string:
            "https://www.googleapis.com/oauth2/v2/userinfo?access_token=\(token)")!

        return try req.client().get(url).flatMap { res in
            return try res.content.decode(GoogleProfile.self)
                .flatMap { profile in
                let id = profile.id!
                try req.session()["id"] = id
                return GoogleProfile.find(id, on: req)
                    .flatMap { existingProfile in
                    if existingProfile == nil {
                        return profile.create(on: req).map { _ in
                            req.redirect(to: "/")
                        }
                    } else {
                        return profile.save(on: req).map { _ in
                            req.redirect(to: "/")
                        }
                    }
                }
            }
        }
    }

    router.get { req -> Future<Response> in
        let dirs = try req.make(DirectoryConfig.self)
        return try req.streamFile(at: dirs.workDir + "Public/index.html")
    }

    let api = router.grouped("api")
    
    let protected = api.grouped(ImperialMiddleware()) { protected in
        let projectController = ProjectController()

        let projects = protected.group("projects")
        projects.get(use: projectController.index)
        projects.post(use: projectController.create)
        projects.patch(Project.parameter, use: projectController.update)
        projects.delete(Project.parameter, use: projectController.delete)

        
        projects.group(Project.parameter) { project in
            let partController = PartController()

            let parts = project.group("parts")
            parts.get(use: partController.index)
            parts.post(use: partController.create)
            parts.patch(Part.parameter, use: partController.update)
            parts.delete(Part.parameter, use: partController.delete)
        }

        let statusController = StatusController()

        let statuses = protected.group("statuses")
        statuses.get(use: statusController.index)
        statuses.post(use: statusController.create)
        statuses.patch(Status.parameter, use: statusController.update)
        statuses.delete(Status.parameter, use: statusController.delete)

        let updateController = UpdateController()
        protected.get("init", use: updateController.initialize)
        protected.get("updates", use: updateController.handle)
    }
}
