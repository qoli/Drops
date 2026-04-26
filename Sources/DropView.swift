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
import os.log
import UIKit

private let dropsRenderLog = OSLog(
  subsystem: Bundle.main.bundleIdentifier ?? "Drops",
  category: "DropsRender"
)

private func dropsRenderNotice(_ message: String) {
  os_log("%{public}@", log: dropsRenderLog, type: .default, message)
  print("[DropsRender] \(message)")
}

internal final class DropView: UIView {
  required init(drop: Drop) {
    self.drop = drop
    super.init(frame: .zero)

    configureBackgroundHierarchy()
    configureContentHierarchy()
    apply(drop: drop)
  }

  required init?(coder _: NSCoder) {
    return nil
  }

  override var frame: CGRect {
    didSet {
      if #available(iOS 26.0, *) {
        // No main-layer shaping on iOS 26+; glass view gets shaped in layoutSubviews.
      } else {
        layer.cornerRadius = frame.cornerRadius
      }
    }
  }

  override var bounds: CGRect {
    didSet {
      if #available(iOS 26.0, *) {
        // No main-layer shaping on iOS 26+; glass view gets shaped in layoutSubviews.
      } else {
        layer.cornerRadius = frame.cornerRadius
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    if #available(iOS 26.0, *) {
      let radius = bounds.height / 2
      glassBackgroundView.layer.masksToBounds = true
      glassBackgroundView.layer.cornerCurve = .continuous
      glassBackgroundView.layer.cornerRadius = radius

      glassTintOverlay.layer.masksToBounds = true
      glassTintOverlay.layer.cornerCurve = .continuous
      glassTintOverlay.layer.cornerRadius = radius

      layer.shadowPath = nil
    } else {
      let radius = bounds.height / 2
      layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true else {
      return
    }

    refreshAdaptiveAppearance(for: drop)
  }

  override func tintColorDidChange() {
    super.tintColorDidChange()

    guard drop.progress != nil else { return }
    progressView.configure(progress: drop.progress, tintColor: resolvedProgressTint(for: drop))
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()

    guard window != nil else { return }
    progressView.restartIndeterminateAnimationIfNeeded(reason: "DropView.didMoveToWindow")
  }

  private(set) var drop: Drop
  private var layoutConstraints: [NSLayoutConstraint] = []
  private var contentTapGesture: UITapGestureRecognizer?

  func createLayoutConstraints(for drop: Drop) -> [NSLayoutConstraint] {
    var constraints: [NSLayoutConstraint] = [
      imageView.heightAnchor.constraint(equalToConstant: 25),
      imageView.widthAnchor.constraint(equalToConstant: 25),
      trailingContainer.heightAnchor.constraint(equalToConstant: 30),
      trailingContainer.widthAnchor.constraint(equalToConstant: 30)
    ]

    var insets = UIEdgeInsets(top: 7.5, left: 12.5, bottom: 7.5, right: 12.5)
    let hasTrailingControl = hasTrailingControl(for: drop)

    if drop.icon == nil {
      insets.left = 40
    }

    if !hasTrailingControl {
      insets.right = 40
    }

    if drop.subtitle == nil {
      insets.top = 15
      insets.bottom = 15

      if hasTrailingControl {
        insets.top = 10
        insets.bottom = 10
        insets.right = 10
      }
    }

    if drop.icon == nil, !hasTrailingControl {
      insets.left = 50
      insets.right = 50
    }

    constraints += [
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
      stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: insets.top),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
    ]

    return constraints
  }

  func update(drop: Drop) {
    apply(drop: drop)
  }

  @objc
  func didTapButton() {
    drop.action?.handler()
  }

  private func apply(drop: Drop) {
    self.drop = drop
    updateLayoutConstraints(for: drop)
    configureViews(for: drop)
  }

  private func updateLayoutConstraints(for drop: Drop) {
    NSLayoutConstraint.deactivate(layoutConstraints)
    layoutConstraints = createLayoutConstraints(for: drop)
    NSLayoutConstraint.activate(layoutConstraints)
  }

  private func configureBackgroundHierarchy() {
    if #available(iOS 26.0, *) {
      isOpaque = false
      backgroundColor = .clear
      layer.allowsGroupOpacity = false

      insertSubview(glassBackgroundView, at: 0)
      glassBackgroundView.contentView.addSubview(glassTintOverlay)
      NSLayoutConstraint.activate([
        glassBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
        glassBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
        glassBackgroundView.topAnchor.constraint(equalTo: topAnchor),
        glassBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
        glassTintOverlay.leadingAnchor.constraint(equalTo: glassBackgroundView.contentView.leadingAnchor),
        glassTintOverlay.trailingAnchor.constraint(equalTo: glassBackgroundView.contentView.trailingAnchor),
        glassTintOverlay.topAnchor.constraint(equalTo: glassBackgroundView.contentView.topAnchor),
        glassTintOverlay.bottomAnchor.constraint(equalTo: glassBackgroundView.contentView.bottomAnchor)
      ])
    } else {
      backgroundColor = .secondarySystemBackground
    }
  }

  private func configureContentHierarchy() {
    addSubview(stackView)
    trailingContainer.addSubview(button)
    trailingContainer.addSubview(progressView)

    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: trailingContainer.leadingAnchor),
      button.trailingAnchor.constraint(equalTo: trailingContainer.trailingAnchor),
      button.topAnchor.constraint(equalTo: trailingContainer.topAnchor),
      button.bottomAnchor.constraint(equalTo: trailingContainer.bottomAnchor),
      progressView.leadingAnchor.constraint(equalTo: trailingContainer.leadingAnchor),
      progressView.trailingAnchor.constraint(equalTo: trailingContainer.trailingAnchor),
      progressView.topAnchor.constraint(equalTo: trailingContainer.topAnchor),
      progressView.bottomAnchor.constraint(equalTo: trailingContainer.bottomAnchor)
    ])
  }

  private func configureViews(for drop: Drop) {
    if #available(iOS 26.0, *) {
      clipsToBounds = false
    } else {
      clipsToBounds = true
    }

    titleLabel.text = drop.title
    titleLabel.numberOfLines = drop.titleNumberOfLines

    subtitleLabel.text = drop.subtitle
    subtitleLabel.numberOfLines = drop.subtitleNumberOfLines
    subtitleLabel.isHidden = drop.subtitle == nil

    if let icon = drop.icon {
      if let accent = drop.accentColor {
        imageView.image = icon.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = accent
      } else {
        imageView.image = icon
        imageView.tintColor = UIAccessibility.isDarkerSystemColorsEnabled ? .label : .secondaryLabel
      }
    } else {
      imageView.image = nil
    }
    imageView.isHidden = drop.icon == nil

    let progressTint = resolvedProgressTint(for: drop)
    progressView.configure(progress: drop.progress, tintColor: progressTint)
    progressView.isHidden = drop.progress == nil
    dropsRenderNotice(
      """
      DropView configure title=\(drop.title) subtitle=\(drop.subtitle ?? "nil") \
      id=\(drop.id ?? "nil") progress=\(Self.progressDescription(drop.progress)) \
      progressHidden=\(self.progressView.isHidden) trailingHidden=\(self.trailingContainer.isHidden)
      """
    )

    button.setImage(drop.action?.icon, for: .normal)
    button.isHidden = drop.progress != nil || drop.action?.icon == nil
    if let accent = drop.accentColor {
      button.backgroundColor = accent
      button.tintColor = .white
    } else {
      button.backgroundColor = .link
      button.tintColor = .white
    }

    trailingContainer.isHidden = !hasTrailingControl(for: drop)

    let isTapActionEnabled = drop.action != nil && (drop.progress != nil || drop.action?.icon == nil)
    if isTapActionEnabled {
      if contentTapGesture == nil {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapButton))
        addGestureRecognizer(tap)
        contentTapGesture = tap
      }
    } else if let contentTapGesture {
      removeGestureRecognizer(contentTapGesture)
      self.contentTapGesture = nil
    }

    stackView.spacing = drop.icon != nil && hasTrailingControl(for: drop) ? 20 : 15

    refreshAdaptiveAppearance(for: drop)
  }

  private func refreshAdaptiveAppearance(for drop: Drop) {
    titleLabel.textColor = .label
    subtitleLabel.textColor = resolvedSecondaryForegroundColor()

    if drop.icon != nil, drop.accentColor == nil {
      imageView.tintColor = resolvedSecondaryForegroundColor()
    }

    updateBackgroundAppearance(for: drop)
  }

  private func updateBackgroundAppearance(for drop: Drop) {
    if #available(iOS 26.0, *) {
      layer.shadowOpacity = 0
      layer.shadowRadius = 0
      layer.shadowOffset = .zero
      layer.shouldRasterize = false
      layer.masksToBounds = false

      if UIAccessibility.isReduceTransparencyEnabled {
        backgroundColor = .secondarySystemBackground
      } else {
        backgroundColor = .clear
      }

      if let tint = drop.glassTintColor {
        glassTintOverlay.isHidden = false
        glassTintOverlay.backgroundColor = tint.withAlphaComponent(Self.glassTintAlpha)
      } else {
        glassTintOverlay.isHidden = true
        glassTintOverlay.backgroundColor = .clear
      }
    } else {
      layer.shadowColor = UIColor.black.cgColor
      layer.shadowOffset = .zero
      layer.shadowRadius = 25
      layer.shadowOpacity = 0.15
      layer.shouldRasterize = true
      #if os(iOS)
      layer.rasterizationScale = UIScreen.main.scale
      #endif
      layer.masksToBounds = false
    }
  }

  private func hasTrailingControl(for drop: Drop) -> Bool {
    drop.progress != nil || drop.action?.icon != nil
  }

  private func resolvedProgressTint(for drop: Drop) -> UIColor {
    drop.accentColor ?? tintColor ?? .dropsProgressDefault
  }

  private func resolvedSecondaryForegroundColor() -> UIColor {
    UIAccessibility.isDarkerSystemColorsEnabled ? .label : .secondaryLabel
  }

  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.textColor = .label
    label.font = UIFont.preferredFont(forTextStyle: .subheadline).bold
    label.adjustsFontForContentSizeCategory = true
    label.adjustsFontSizeToFitWidth = true
    return label
  }()

  lazy var subtitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.textColor = .secondaryLabel
    label.font = UIFont.preferredFont(forTextStyle: .subheadline)
    label.adjustsFontForContentSizeCategory = true
    label.adjustsFontSizeToFitWidth = true
    return label
  }()

  lazy var imageView: UIImageView = {
    let view = RoundImageView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.contentMode = .scaleAspectFit
    view.clipsToBounds = true
    view.tintColor = .secondaryLabel
    return view
  }()

  lazy var button: UIButton = {
    let button = RoundButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    button.clipsToBounds = true
    button.backgroundColor = .link
    button.tintColor = .white
    button.imageView?.contentMode = .scaleAspectFit
    button.contentEdgeInsets = .init(top: 7.5, left: 7.5, bottom: 7.5, right: 7.5)
    return button
  }()

  lazy var progressView: CircularProgressView = {
    let view = CircularProgressView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  lazy var labelsStackView: UIStackView = {
    let view = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    view.translatesAutoresizingMaskIntoConstraints = false
    view.axis = .vertical
    view.alignment = .fill
    view.distribution = .fill
    view.spacing = -1
    return view
  }()

  lazy var trailingContainer: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  lazy var stackView: UIStackView = {
    let view = UIStackView(arrangedSubviews: [imageView, labelsStackView, trailingContainer])
    view.translatesAutoresizingMaskIntoConstraints = false
    view.axis = .horizontal
    view.alignment = .center
    view.distribution = .fill
    view.spacing = 15
    return view
  }()

  private lazy var glassBackgroundView: UIVisualEffectView = {
    let effect: UIVisualEffect
    if #available(iOS 26.0, *) {
      effect = UIGlassEffect(style: .regular)
    } else {
      effect = UIBlurEffect(style: .systemThinMaterial)
    }
    let view = UIVisualEffectView(effect: effect)
    view.isOpaque = false
    view.backgroundColor = .clear
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    return view
  }()

  private lazy var glassTintOverlay: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isUserInteractionEnabled = false
    view.isHidden = true
    view.backgroundColor = .clear
    return view
  }()

  private static let glassTintAlpha: CGFloat = 0.12

  private static func progressDescription(_ progress: Drop.Progress?) -> String {
    switch progress {
    case let .determinate(value):
      return "determinate(\(String(format: "%.3f", value)))"
    case .indeterminate:
      return "indeterminate"
    case nil:
      return "nil"
    }
  }
}

internal final class CircularProgressView: UIView {
  private enum Constants {
    static let lineWidth: CGFloat = 6
    static let indeterminateStrokeStart: CGFloat = 0.12
    static let indeterminateStrokeEnd: CGFloat = 0.62
    static let animationKey = "drops.indeterminate.rotation"
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    isAccessibilityElement = false

    [trackLayer, progressLayer].forEach(layer.addSublayer)

    trackLayer.fillColor = UIColor.clear.cgColor
    trackLayer.lineWidth = Constants.lineWidth

    progressLayer.fillColor = UIColor.clear.cgColor
    progressLayer.lineWidth = Constants.lineWidth
    progressLayer.lineCap = .round
  }

  required init?(coder _: NSCoder) {
    return nil
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let inset = Constants.lineWidth / 2 + 2
    let ringRect = bounds.insetBy(dx: inset, dy: inset)
    let path = UIBezierPath(ovalIn: ringRect).cgPath
    let rotation = CATransform3DMakeRotation(-.pi / 2, 0, 0, 1)

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    [trackLayer, progressLayer].forEach {
      $0.path = path
      $0.frame = bounds
      $0.transform = rotation
    }
    CATransaction.commit()
  }

  private(set) var progress: Drop.Progress?
  private(set) var resolvedTintColor: UIColor = .dropsProgressDefault

  var isAnimatingIndeterminate: Bool {
    progressLayer.animation(forKey: Constants.animationKey) != nil
  }

  func configure(progress: Drop.Progress?, tintColor: UIColor) {
    self.progress = progress
    resolvedTintColor = tintColor
    dropsRenderNotice(
      "CircularProgressView configure progress=\(Self.progressDescription(progress)) tint=\(tintColor.description)"
    )

    CATransaction.begin()
    CATransaction.setDisableActions(true)

    trackLayer.strokeColor = UIColor.tertiaryLabel.withAlphaComponent(0.15).cgColor

    progressLayer.strokeColor = tintColor.cgColor
    progressLayer.shadowOpacity = 0
    progressLayer.shadowRadius = 0
    progressLayer.shadowOffset = .zero

    switch progress {
    case let .determinate(value):
      progressLayer.removeAnimation(forKey: Constants.animationKey)
      dropsRenderNotice(
        "CircularProgressView apply determinate value=\(String(format: "%.3f", value))"
      )
      progressLayer.strokeStart = 0
      progressLayer.strokeEnd = CGFloat(min(1, max(0, value)))

    case .indeterminate:
      dropsRenderNotice("CircularProgressView apply indeterminate")
      progressLayer.strokeStart = Constants.indeterminateStrokeStart
      progressLayer.strokeEnd = Constants.indeterminateStrokeEnd
      startIndeterminateAnimationIfNeeded()

    case nil:
      progressLayer.removeAnimation(forKey: Constants.animationKey)
      dropsRenderNotice("CircularProgressView apply nil progress")
      progressLayer.strokeStart = 0
      progressLayer.strokeEnd = 0
    }

    CATransaction.commit()
  }

  func restartIndeterminateAnimationIfNeeded(reason: String) {
    guard case .indeterminate = progress else { return }

    progressLayer.removeAnimation(forKey: Constants.animationKey)
    dropsRenderNotice("CircularProgressView restart indeterminate animation reason=\(reason)")
    startIndeterminateAnimationIfNeeded()
  }

  private func startIndeterminateAnimationIfNeeded() {
    guard progressLayer.animation(forKey: Constants.animationKey) == nil else {
      dropsRenderNotice("CircularProgressView indeterminate animation already active")
      return
    }

    let animation = CABasicAnimation(keyPath: "transform.rotation.z")
    animation.fromValue = 0
    animation.toValue = CGFloat.pi * 2
    animation.duration = 1.15
    animation.repeatCount = .infinity
    animation.timingFunction = CAMediaTimingFunction(name: .linear)
    progressLayer.add(animation, forKey: Constants.animationKey)
    dropsRenderNotice("CircularProgressView started indeterminate animation")
  }

  private let trackLayer = CAShapeLayer()
  private let progressLayer = CAShapeLayer()

  private static func progressDescription(_ progress: Drop.Progress?) -> String {
    switch progress {
    case let .determinate(value):
      return "determinate(\(String(format: "%.3f", value)))"
    case .indeterminate:
      return "indeterminate"
    case nil:
      return "nil"
    }
  }
}

final class RoundButton: UIButton {
  override var bounds: CGRect {
    didSet { layer.cornerRadius = frame.cornerRadius }
  }
}

final class RoundImageView: UIImageView {
  override var bounds: CGRect {
    didSet { layer.cornerRadius = frame.cornerRadius }
  }
}

extension UIFont {
  var bold: UIFont {
    guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
    return UIFont(descriptor: descriptor, size: pointSize)
  }
}

extension CGRect {
  var cornerRadius: CGFloat {
    return min(width, height) / 2
  }
}

extension UIColor {
  static let dropsProgressDefault = UIColor.systemBlue
}
#endif
