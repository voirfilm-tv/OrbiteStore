import Foundation
import CoreGraphics

let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
for window in windows {
    guard let owner = window[kCGWindowOwnerName as String] as? String, owner == "OrbitStore",
          let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
          let windowID = window[kCGWindowNumber as String] as? Int,
          let rect = window[kCGWindowBounds as String] as? [String: Any],
          let width = rect["Width"] as? NSNumber, width.intValue >= 700
    else { continue }
    print(windowID)
    exit(0)
}
fputs("No visible OrbitStore window; refusing to produce a fake screenshot.\n", stderr)
exit(2)
