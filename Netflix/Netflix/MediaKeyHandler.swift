import Cocoa

class MediaKeyHandler {
    static func setup() {
        NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { event in
            // keyCode 16 = Play/Pause, 20 = Previous, 19 = Next
            if event.type == .systemDefined && event.subtype.rawValue == 8 {
                let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
                let keyFlags = (event.data1 & 0x0000FFFF)
                let keyDown = (keyFlags & 0xFF00) >> 8 == 0xA

                if keyDown {
                    switch Int32(keyCode) {
                    case 16: // Play/Pause
                        NotificationCenter.default.post(name: .mediaPlayPause, object: nil)
                    default:
                        break
                    }
                }
            }
            return event
        }
    }
}

extension Notification.Name {
    static let mediaPlayPause = Notification.Name("mediaPlayPause")
}
