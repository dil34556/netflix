import XCTest

class NetflixNavigationTests: XCTestCase {

    func testAllowedHosts() {
        let allowedHosts = [
            "netflix.com",
            "www.netflix.com",
            "help.netflix.com",
            "nflxvideo.net",
            "cdn.nflxvideo.net",
            "nflximg.net",
            "nflxso.net",
            "nflxext.com"
        ]
        
        for host in allowedHosts {
            XCTAssertTrue(NetflixHostPolicy.isAllowed(host), "Should allow \(host)")
        }
    }

    func testBlockedHosts() {
        let blockedHosts = [
            "google.com",
            "www.google.com",
            "youtube.com",
            "netflix.org", // Incorrect TLD
            "malicious-netflix.com",
            "",
            nil
        ]
        
        for host in blockedHosts {
            XCTAssertFalse(NetflixHostPolicy.isAllowed(host), "Should block \(String(describing: host))")
        }
    }
}
