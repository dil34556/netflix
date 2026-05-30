struct NetflixHostPolicy {
    private static let allowedHosts = [
        "netflix.com",
        "nflxvideo.net",
        "nflximg.net",
        "nflxso.net",
        "nflxext.com"
    ]

    static func isAllowed(_ host: String?) -> Bool {
        guard let host = host?.lowercased(), !host.isEmpty else {
            return false
        }

        return allowedHosts.contains { allowedHost in
            host == allowedHost || host.hasSuffix("." + allowedHost)
        }
    }
}
