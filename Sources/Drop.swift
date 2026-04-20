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

/// An object representing a drop.
@available(iOSApplicationExtension, unavailable)
public struct Drop: ExpressibleByStringLiteral {
  /// Create a new drop.
  /// - Parameters:
  ///   - title: Title.
  ///   - titleNumberOfLines: Maximum number of lines that `title` can occupy. Defaults to `1`.
  ///   A value of 0 means no limit.
  ///   - subtitle: Optional subtitle. Defaults to `nil`.
  ///   - subtitleNumberOfLines: Maximum number of lines that `subtitle` can occupy. Defaults to `1`.
  ///   A value of 0 means no limit.
  ///   - icon: Optional icon.
  ///   - action: Optional action.
  ///   - position: Position. Defaults to `Drop.Position.top`.
  ///   - duration: Duration. Defaults to `Drop.Duration.recommended`.
  ///   - accessibility: Accessibility options. Defaults to `nil` which will use "title, subtitle" as its message.
  ///   - accentColor: Optional accent color to tint the icon and the action button background.
  ///   If `nil`, system defaults are used.
  ///   - glassTintColor: Optional tint color to overlay the glass effect (iOS 26+).
  ///   If `nil`, no extra tint overlay is applied.
  ///   - maxWidth: Optional maximum width for the drop content. If `nil`, a platform-tuned default is used.
  public init(
    title: String,
    titleNumberOfLines: Int = 1,
    subtitle: String? = nil,
    subtitleNumberOfLines: Int = 1,
    icon: UIImage? = nil,
    action: Action? = nil,
    position: Position = .top,
    duration: Duration = .recommended,
    accessibility: Accessibility? = nil,
    accentColor: UIColor? = nil,
    glassTintColor: UIColor? = nil,
    maxWidth: CGFloat? = nil,
    id: String? = nil,
    progress: Progress? = nil
  ) {
    if let id = id?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
      self.id = id
    }
    self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    self.titleNumberOfLines = titleNumberOfLines
    if let subtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines), !subtitle.isEmpty {
      self.subtitle = subtitle
    }
    self.subtitleNumberOfLines = subtitleNumberOfLines
    self.icon = icon
    self.action = action
    self.position = position
    self.duration = duration
    self.accessibility = accessibility
    ?? .init(message: [title, subtitle].compactMap { $0 }.joined(separator: ", "))
    self.accentColor = accentColor
    self.glassTintColor = glassTintColor
    self.maxWidth = maxWidth
    self.progress = progress
  }

  /// Create a new accessibility object.
  /// - Parameter message: Message to be announced when the drop is shown. Defaults to drop's "title, subtitle"
  public init(stringLiteral title: String) {
    self.title = title
    titleNumberOfLines = 1
    subtitleNumberOfLines = 1
    position = .top
    duration = .recommended
    accessibility = .init(message: title)
    accentColor = nil
    glassTintColor = nil
    maxWidth = nil
    progress = nil
  }

  /// Stable identifier used to update an existing drop in place.
  public var id: String?

  /// Title.
  public var title: String

  /// Maximum number of lines that `title` can occupy. A value of 0 means no limit.
  public var titleNumberOfLines: Int

  /// Subtitle.
  public var subtitle: String?

  /// Maximum number of lines that `subtitle` can occupy. A value of 0 means no limit.
  public var subtitleNumberOfLines: Int

  /// Icon.
  public var icon: UIImage?

  /// Action.
  public var action: Action?

  /// Position.
  public var position: Position

  /// Duration.
  public var duration: Duration

  /// Accessibility.
  public var accessibility: Accessibility

  /// Optional accent color used to tint the icon and the action button background.
  public var accentColor: UIColor?

  /// Optional tint color overlay for the glass effect (iOS 26+ only).
  public var glassTintColor: UIColor?

  /// Optional maximum width used during presentation.
  public var maxWidth: CGFloat?

  /// Optional progress indicator.
  public var progress: Progress?
}

public extension Drop {
  /// An enum representing drop presentation position.
  enum Position: Equatable {
    /// Drop is presented from top.
    case top
    /// Drop is presented from bottom.
    case bottom
  }
}

public extension Drop {
  /// An enum representing a drop duration on screen.
  enum Duration: Equatable, ExpressibleByFloatLiteral {
    /// Hides the drop after 2.0 seconds.
    case recommended
    /// Hides the drop after the specified number of seconds.
    case seconds(TimeInterval)
    /// Keeps the drop visible until it is hidden manually.
    case untilHidden

    /// Create a new duration object.
    /// - Parameter value: Duration in seconds
    public init(floatLiteral value: TimeInterval) {
      self = .seconds(value)
    }

    internal var value: TimeInterval? {
      switch self {
      case .recommended:
        return 2.0
      case let .seconds(custom):
        return abs(custom)
      case .untilHidden:
        return nil
      }
    }
  }
}

public extension Drop {
  /// An enum representing the drop progress indicator.
  enum Progress: Equatable {
    case determinate(Double)
    case indeterminate

    /// Normalized progress value in the `0...1` range when determinate.
    var fractionCompleted: Double? {
      switch self {
      case let .determinate(value):
        return min(1, max(0, value))
      case .indeterminate:
        return nil
      }
    }
  }
}

public extension Drop {
  /// An object representing a drop action.
  struct Action {
    /// Create a new action.
    /// - Parameters:
    ///   - icon: Optional icon image.
    ///   - handler: Handler to be called when the drop is tapped.
    public init(icon: UIImage? = nil, handler: @escaping () -> Void) {
      self.icon = icon
      self.handler = handler
    }

    /// Icon.
    public var icon: UIImage?

    /// Handler.
    public var handler: () -> Void
  }
}

public extension Drop {
  /// An object representing accessibility options.
  struct Accessibility: ExpressibleByStringLiteral {
    /// Create a new accessibility object.
    /// - Parameter message: Message to be announced when the drop is shown. Defaults to drop's "title, subtitle"
    public init(message: String) {
      self.message = message
    }

    /// Create a new accessibility object.
    /// - Parameter message: Message to be announced when the drop is shown. Defaults to drop's "title, subtitle"
    public init(stringLiteral message: String) {
      self.message = message
    }

    /// Accessibility message to be announced when the drop is shown.
    public let message: String
  }
}

internal extension Drop {
  func replacingCurrent(with incoming: Drop) -> Drop {
    var updated = self
    updated.id = incoming.id
    updated.title = incoming.title
    updated.titleNumberOfLines = incoming.titleNumberOfLines
    updated.subtitle = incoming.subtitle
    updated.subtitleNumberOfLines = incoming.subtitleNumberOfLines
    updated.icon = incoming.icon
    updated.duration = incoming.duration
    updated.accessibility = incoming.accessibility
    updated.accentColor = incoming.accentColor
    updated.glassTintColor = incoming.glassTintColor
    updated.maxWidth = incoming.maxWidth
    updated.progress = incoming.progress
    return updated
  }
}
#endif
