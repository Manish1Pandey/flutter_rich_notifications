import UIKit
import UserNotifications
import UserNotificationsUI

/// Notification Content Extension renderer for rich push notifications.
///
/// Default look:
///  ┌────────────────────────────┐
///  │                            │  ← hero image (rounded, 200pt)
///  │                            │
///  ├────────────────────────────┤
///  │ Title in semibold          │  ← title (17pt semibold)
///  │ Body wraps as many lines   │  ← body (14pt regular,
///  │ as it needs — no limit.    │     1.4 line spacing)
///  └────────────────────────────┘
///
/// ─── Customization ─────────────────────────────────────────────
/// Tweak the `Design` block below for the common cases (image
/// position, sizes, colors, padding). For deeper layout changes,
/// subclass this file and override the `open` methods at the bottom.
class NotificationViewController: UIViewController, UNNotificationContentExtension {

    // MARK: - Design knobs (tweak these for the common cases) ───────

    /// Where the hero image sits relative to the text.
    enum ImagePosition { case top, bottom, none }

    /// Image-related knobs.
    var imagePosition: ImagePosition = .top
    var imageHeight: CGFloat = 200
    var imageCornerRadius: CGFloat = 12

    /// Typography.
    var titleFont: UIFont = .systemFont(ofSize: 17, weight: .semibold)
    var bodyFont: UIFont = .systemFont(ofSize: 14, weight: .regular)
    var bodyLineSpacing: CGFloat = 3

    /// Colors. Defaults adapt to light/dark mode automatically.
    var titleColor: UIColor = .resolveLabel()
    var bodyColor: UIColor = .resolveSecondaryLabel()
    var cardBackgroundColor: UIColor = .clear
    var accentColor: UIColor? = nil   // set to a brand UIColor to enable left stripe

    /// Spacing.
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 14
    var titleBodySpacing: CGFloat = 6
    var imageToTextSpacing: CGFloat = 12
    var accentStripeWidth: CGFloat = 4

    // MARK: - Subviews ─────────────────────────────────────────────

    private let cardView = UIView()
    private let accentStripe = UIView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let heroImageView = UIImageView()

    // MARK: - Lifecycle ─────────────────────────────────────────────

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        buildHierarchy()
        styleSubviews()
        installConstraints()
    }

    // MARK: - UNNotificationContentExtension ────────────────────────

    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        applyTitle(content.title)
        applyBody(content.body)

        if let attachment = content.attachments.first,
           let image = loadImage(from: attachment) {
            heroImageView.image = image
            heroImageView.isHidden = imagePosition == .none
        } else {
            heroImageView.image = nil
            heroImageView.isHidden = true
        }

        view.setNeedsLayout()
        view.layoutIfNeeded()
        preferredContentSize = CGSize(
            width: view.bounds.width,
            height: computePreferredHeight()
        )
    }

    // MARK: - Open hooks (override in subclass for deeper changes) ──

    open func applyTitle(_ text: String) {
        titleLabel.text = text.isEmpty ? nil : text
    }

    open func applyBody(_ text: String) {
        guard !text.isEmpty else { bodyLabel.text = nil; return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = bodyLineSpacing
        bodyLabel.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraph,
                .font: bodyFont,
                .foregroundColor: bodyColor,
            ]
        )
    }

    // MARK: - Layout ────────────────────────────────────────────────

    private func buildHierarchy() {
        view.addSubview(cardView)
        cardView.addSubview(accentStripe)
        cardView.addSubview(heroImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(bodyLabel)

        [cardView, accentStripe, heroImageView, titleLabel, bodyLabel]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    }

    private func styleSubviews() {
        cardView.backgroundColor = cardBackgroundColor

        accentStripe.backgroundColor = accentColor ?? .clear
        accentStripe.layer.cornerRadius = 2
        accentStripe.isHidden = (accentColor == nil)

        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.layer.cornerRadius = imageCornerRadius

        titleLabel.font = titleFont
        titleLabel.textColor = titleColor
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
    }

    private func installConstraints() {
        let leadingTextAnchor = accentStripe.isHidden
            ? cardView.leadingAnchor
            : accentStripe.trailingAnchor
        let leadingTextConstant: CGFloat = accentStripe.isHidden
            ? horizontalPadding
            : horizontalPadding - accentStripeWidth

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: view.topAnchor),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            accentStripe.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: horizontalPadding / 2),
            accentStripe.topAnchor.constraint(equalTo: cardView.topAnchor, constant: verticalPadding),
            accentStripe.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -verticalPadding),
            accentStripe.widthAnchor.constraint(equalToConstant: accentStripeWidth),
        ])

        switch imagePosition {
        case .top:
            NSLayoutConstraint.activate([
                heroImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: verticalPadding),
                heroImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: horizontalPadding),
                heroImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalPadding),
                heroImageView.heightAnchor.constraint(equalToConstant: imageHeight),

                titleLabel.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: imageToTextSpacing),
                titleLabel.leadingAnchor.constraint(equalTo: leadingTextAnchor, constant: leadingTextConstant),
                titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalPadding),

                bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: titleBodySpacing),
                bodyLabel.leadingAnchor.constraint(equalTo: leadingTextAnchor, constant: leadingTextConstant),
                bodyLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalPadding),
                bodyLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -verticalPadding),
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: verticalPadding),
                titleLabel.leadingAnchor.constraint(equalTo: leadingTextAnchor, constant: leadingTextConstant),
                titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalPadding),

                bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: titleBodySpacing),
                bodyLabel.leadingAnchor.constraint(equalTo: leadingTextAnchor, constant: leadingTextConstant),
                bodyLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalPadding),

                heroImageView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: imageToTextSpacing),
                heroImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: horizontalPadding),
                heroImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalPadding),
                heroImageView.heightAnchor.constraint(equalToConstant: imageHeight),
                heroImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -verticalPadding),
            ])
        case .none:
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: verticalPadding),
                titleLabel.leadingAnchor.constraint(equalTo: leadingTextAnchor, constant: leadingTextConstant),
                titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalPadding),

                bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: titleBodySpacing),
                bodyLabel.leadingAnchor.constraint(equalTo: leadingTextAnchor, constant: leadingTextConstant),
                bodyLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -horizontalPadding),
                bodyLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -verticalPadding),
            ])
        }
    }

    // MARK: - Helpers ───────────────────────────────────────────────

    private func loadImage(from attachment: UNNotificationAttachment) -> UIImage? {
        let didStart = attachment.url.startAccessingSecurityScopedResource()
        defer { if didStart { attachment.url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: attachment.url) else { return nil }
        return UIImage(data: data)
    }

    private func computePreferredHeight() -> CGFloat {
        let availableWidth = view.bounds.width - (horizontalPadding * 2)
        let titleHeight = titleLabel.text.map { textHeight($0, font: titleFont, width: availableWidth, maxLines: 2) } ?? 0
        let bodyHeight = bodyLabel.attributedText.map { attrHeight($0, width: availableWidth) } ?? 0
        let imageBlock = (heroImageView.isHidden ? 0 : imageHeight + imageToTextSpacing)

        return verticalPadding + imageBlock + titleHeight
            + (bodyHeight > 0 ? titleBodySpacing + bodyHeight : 0)
            + verticalPadding
    }

    private func textHeight(_ s: String, font: UIFont, width: CGFloat, maxLines: Int) -> CGFloat {
        let bound = (s as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        let h = ceil(bound.height)
        return maxLines > 0 ? min(h, ceil(font.lineHeight * CGFloat(maxLines))) : h
    }

    private func attrHeight(_ s: NSAttributedString, width: CGFloat) -> CGFloat {
        let bound = s.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(bound.height)
    }
}

// MARK: - Dark mode-aware default colors

private extension UIColor {
    static func resolveLabel() -> UIColor {
        if #available(iOS 13.0, *) { return .label }
        return .black
    }
    static func resolveSecondaryLabel() -> UIColor {
        if #available(iOS 13.0, *) { return .secondaryLabel }
        return .darkGray
    }
}
