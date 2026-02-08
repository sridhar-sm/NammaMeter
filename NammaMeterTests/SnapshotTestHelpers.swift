import SnapshotTesting
import SwiftUI
import UIKit

enum SnapshotTestHelpers {
  @MainActor
  static func assertSwiftUIViewSnapshot<Content: View>(
    _ view: Content,
    size: CGSize,
    colorScheme: ColorScheme = .light,
    precision: Float = 0.98,
    perceptualPrecision: Float = 0.98,
    record: Bool = false,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line
  ) {
    let styledView = view.preferredColorScheme(colorScheme)
    let image = render(styledView, size: size)
    let suffix = snapshotNameSuffix(colorScheme: colorScheme)
    assertSnapshot(
      of: image,
      as: .image(precision: precision, perceptualPrecision: perceptualPrecision),
      named: suffix,
      record: record,
      file: file,
      testName: testName,
      line: line
    )
  }

  @MainActor
  private static func render<Content: View>(_ view: Content, size: CGSize) -> UIImage {
    if #available(iOS 16.0, *) {
      let renderer = ImageRenderer(content: view)
      renderer.scale = UIScreen.main.scale
      renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
      if let image = renderer.uiImage {
        return image
      }
    }

    let controller = UIHostingController(rootView: view)
    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    window.rootViewController = controller
    window.makeKeyAndVisible()

    controller.view.frame = window.bounds
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()

    let format = UIGraphicsImageRendererFormat(for: controller.traitCollection)
    let renderer = UIGraphicsImageRenderer(bounds: controller.view.bounds, format: format)
    let image = renderer.image { context in
      controller.view.layer.render(in: context.cgContext)
    }

    window.isHidden = true
    window.rootViewController = nil

    return image
  }

  private static func snapshotNameSuffix(colorScheme: ColorScheme) -> String? {
    let environment = ProcessInfo.processInfo.environment
    let rawName = environment["SNAPSHOT_DEVICE_NAME"] ?? environment["SIMULATOR_DEVICE_NAME"]
    guard let rawValue = rawName?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      !rawValue.isEmpty
    else {
      return nil
    }
    let deviceName = rawValue.replacingOccurrences(of: " ", with: "_")
    let themeSuffix = colorScheme == .dark ? "_dark" : ""
    return deviceName + themeSuffix
  }
}
