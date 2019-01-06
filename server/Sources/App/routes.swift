import Vapor
import Imperial

public func routes(_ router: Router) throws {
    try router.oAuth(
        from: Google.self,
        authenticate: "google",
        callback: "http://parts.botprovoking.org:8080/callback/google",
        scope: ["profile"]) { (req, token) in

        let url = URL(string:
            "https://www.googleapis.com/oauth2/v2/userinfo?access_token=\(token)")!

        return try req.client().get(url).flatMap { res in
            return try res.content.decode(GoogleProfile.self)
                .flatMap { profile in
                try req.session()["id"] = profile.id
                return profile.save(on: req).map { _ in
                    req.redirect(to: "/")
                }
            }
        }
    }

    let api = router.grouped("api")
    let protected = api.grouped(ImperialMiddleware())

    let partController = PartController()
    protected.get("parts", use: partController.index)
    protected.post("parts", use: partController.create)
    protected.patch("parts", Part.parameter, use: partController.update)
    protected.delete("parts", Part.parameter, use: partController.delete)

    let updateController = UpdateController()
    protected.get("init", use: updateController.initialize)
    protected.get("updates", use: updateController.handle)
}
