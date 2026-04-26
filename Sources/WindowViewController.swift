//
//  Drops
//
//  Copyright (c) 2021-Present Omar Albeik - https://github.com/omaralbeik
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if os(iOS) || os(visionOS)
import UIKit

internal final class WindowViewController: UIViewController {
  init() {
    let view = PassthroughView()
    let window = PassthroughWindow(hitTestView: view)
    self.window = window
    super.init(nibName: nil, bundle: nil)
    self.view = view
    window.rootViewController = self
  }

  required init?(coder _: NSCoder) {
    return nil
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    // Workaround for https://github.com/omaralbeik/Drops/pull/22
    let app = UIApplication.shared
    let windowScene = app.activeWindowScene
    let topViewController = windowScene?.windows.first(where: \.isKeyWindow)?.rootViewController?.top
    if let controller = topViewController, controller === self {
      return .default
    }
    return topViewController?.preferredStatusBarStyle
      ?? windowScene?.statusBarManager?.statusBarStyle
      ?? .default
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true else {
      return
    }

    syncInterfaceStyle()
  }

  func install() {
      #if os(iOS)
    window?.frame = UIScreen.main.bounds
      #endif
    window?.isHidden = false
    if let window = window, let activeScene = UIApplication.shared.activeWindowScene {
      window.windowScene = activeScene
      window.frame = activeScene.coordinateSpace.bounds
      syncInterfaceStyle()
      syncTintColor()
    }
  }

  func uninstall() {
    window?.isHidden = true
    window?.windowScene = nil
    window = nil
  }

  var window: UIWindow?

  private func syncInterfaceStyle() {
    guard let window else { return }

    let interfaceStyle = resolvedSourceInterfaceStyle()
      ?? traitCollection.userInterfaceStyle

    guard interfaceStyle != .unspecified else { return }

    window.overrideUserInterfaceStyle = interfaceStyle
    overrideUserInterfaceStyle = interfaceStyle
  }

  private func syncTintColor() {
    guard let window else { return }
    guard let tintColor = resolvedSourceTintColor() else { return }

    window.tintColor = tintColor
    view.tintColor = tintColor
  }

  private func resolvedSourceInterfaceStyle() -> UIUserInterfaceStyle? {
    guard let activeScene = UIApplication.shared.activeWindowScene else { return nil }

    let candidateWindows = activeScene.windows.filter { candidate in
      candidate !== window && !candidate.isHidden && candidate.alpha > 0.01
    }

    if let sourceWindow = candidateWindows.first(where: \.isKeyWindow) ?? candidateWindows.last {
      let overrideStyle = sourceWindow.overrideUserInterfaceStyle
      if overrideStyle != .unspecified {
        return overrideStyle
      }

      let traitStyle = sourceWindow.traitCollection.userInterfaceStyle
      if traitStyle != .unspecified {
        return traitStyle
      }
    }

    if let topViewController = candidateWindows.last?.rootViewController?.top {
      let traitStyle = topViewController.traitCollection.userInterfaceStyle
      if traitStyle != .unspecified {
        return traitStyle
      }
    }

    return nil
  }

  private func resolvedSourceTintColor() -> UIColor? {
    guard let activeScene = UIApplication.shared.activeWindowScene else { return nil }

    let candidateWindows = activeScene.windows.filter { candidate in
      candidate !== window && !candidate.isHidden && candidate.alpha > 0.01
    }

    let sourceWindow = candidateWindows.first(where: \.isKeyWindow) ?? candidateWindows.last
    return sourceWindow?.tintColor
  }
}

internal extension UIApplication {
  var activeWindowScene: UIWindowScene? {
    return connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
  }
}

internal extension UIViewController {
  var top: UIViewController? {
    if let controller = self as? UINavigationController {
      return controller.topViewController?.top
    }
    if let controller = self as? UISplitViewController {
      return controller.viewControllers.last?.top
    }
    if let controller = self as? UITabBarController {
      return controller.selectedViewController?.top
    }
    if let controller = presentedViewController {
      return controller.top
    }
    return self
  }
}
#endif
