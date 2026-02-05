import SnapshotTesting
import SwiftUI
import UIKit

enum SnapshotTestHelpers {
  @MainActor
  static func assertSwiftUIViewSnapshot<Content: View>(
    _ view: Content,
    size: CGSize,
    precision: Float = 0.98,
    perceptualPrecision: Float = 0.98,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line
  ) {
    let record = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
    let image = render(view, size: size)
    assertSnapshot(
      of: image,
      as: .image(precision: precision, perceptualPrecision: perceptualPrecision),
      named: snapshotNameSuffix,
      record: record ? true : nil,
      file: file,
      testName: testName,
      line: line
    )
  }

  @MainActor
  private static func render<Content: View>(_ view: Content, size: CGSize) -> UIImage {
    let controller = UIHostingController(rootView: view)
    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    window.rootViewController = controller
    window.makeKeyAndVisible()

    controller.view.frame = window.bounds
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()

    let format = UIGraphicsImageRendererFormat(for: controller.traitCollection)
    let renderer = UIGraphicsImageRenderer(bounds: controller.view.bounds, format: format)
    let image = renderer.image { _ in
      controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }

    window.isHidden = true
    window.rootViewController = nil

    return image
  }

  private static let snapshotNameSuffix: String? = {
    let environment = ProcessInfo.processInfo.environment
    let rawName = environment["SNAPSHOT_DEVICE_NAME"] ?? environment["SIMULATOR_DEVICE_NAME"]
    guard let rawValue = rawName?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      !rawValue.isEmpty
    else {
      return nil
    }
    return rawValue.replacingOccurrences(of: " ", with: "_")
  }()
}
