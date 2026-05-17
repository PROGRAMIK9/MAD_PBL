import Foundation

@objc class MapboxService: NSObject {
    @objc func downloadRegion(_ regionId: String, options: [String: Any], result: @escaping (Bool) -> Void) {
        // Placeholder: integrate Mapbox iOS SDK and implement offline region downloads
        result(true)
    }

    @objc func removeRegion(_ regionId: String, result: @escaping () -> Void) {
        // Placeholder
        result()
    }
}
