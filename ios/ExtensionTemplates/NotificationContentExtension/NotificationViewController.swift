import UIKit
import UserNotifications
import UserNotificationsUI

/// Notification Content Extension template for flutter_rich_notifications.
///
/// Copy this file into a Notification Content Extension target inside your
/// iOS app. The extension renders the expanded notification with a full hero
/// image and full multi-line body when the user long-presses or pulls down
/// the notification.
///
/// Required APNs payload field: `aps.category: "rich_notification"`
/// (must match `UNNotificationExtensionCategory` in the extension's Info.plist)
class NotificationViewController: UIViewController, UNNotificationContentExtension {

    // MARK: - Layout constants
    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 12
    private let titleBodySpacing: CGFloat = 6
    private let bodyImageSpacing: CGFloat = 12
    private let imageHeight: CGFloat = 200
    private let imageCornerRadius: CGFloat = 10

    // MARK: - Subviews
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        if #available(iOS 13.0, *) { label.textColor = .label } else { label.textColor = .black }
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        if #available(iOS 13.0, *) { label.textColor = .secondaryLabel } else { label.textColor = .darkGray }
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let heroImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var imageHeightConstraint: NSLayoutConstraint!
    private var imageTopConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        heroImageView.layer.cornerRadius = imageCornerRadius

        view.addSubview(titleLabel)
        view.addSubview(bodyLabel)
        view.addSubview(heroImageView)

        imageHeightConstraint = heroImageView.heightAnchor.constraint(equalToConstant: imageHeight)
        imageTopConstraint = heroImageView.topAnchor.constraint(
            equalTo: bodyLabel.bottomAnchor,
            constant: bodyImageSpacing
        )

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: verticalPadding),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: titleBodySpacing),
            bodyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            bodyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),

            imageTopConstraint,
            heroImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageHeightConstraint,
            heroImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -verticalPadding),
        ])
    }

    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content

        titleLabel.text = content.title.isEmpty ? nil : content.title
        bodyLabel.text = content.body.isEmpty ? nil : content.body

        if let attachment = content.attachments.first,
           let image = loadImage(from: attachment) {
            heroImageView.image = image
            imageHeightConstraint.constant = imageHeight
            imageTopConstraint.constant = bodyImageSpacing
            heroImageView.isHidden = false
        } else {
            heroImageView.image = nil
            imageHeightConstraint.constant = 0
            imageTopConstraint.constant = 0
            heroImageView.isHidden = true
        }

        view.setNeedsLayout()
        view.layoutIfNeeded()

        preferredContentSize = CGSize(
            width: view.bounds.width,
            height: computePreferredHeight()
        )
    }

    private func loadImage(from attachment: UNNotificationAttachment) -> UIImage? {
        let didStartAccessing = attachment.url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                attachment.url.stopAccessingSecurityScopedResource()
            }
        }
        guard let data = try? Data(contentsOf: attachment.url) else { return nil }
        return UIImage(data: data)
    }

    private func computePreferredHeight() -> CGFloat {
        let availableWidth = view.bounds.width - (horizontalPadding * 2)

        let titleHeight = titleLabel.text.map {
            heightFor($0, font: titleLabel.font, width: availableWidth, maxLines: 2)
        } ?? 0
        let bodyHeight = bodyLabel.text.map {
            heightFor($0, font: bodyLabel.font, width: availableWidth, maxLines: 0)
        } ?? 0

        var total: CGFloat = verticalPadding + titleHeight
        if bodyHeight > 0 { total += titleBodySpacing + bodyHeight }
        if !heroImageView.isHidden { total += bodyImageSpacing + imageHeight }
        total += verticalPadding

        return total
    }

    private func heightFor(_ text: String, font: UIFont, width: CGFloat, maxLines: Int) -> CGFloat {
        let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
        let bounding = (text as NSString).boundingRect(
            with: constraint,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        var height = ceil(bounding.height)
        if maxLines > 0 {
            let cap = font.lineHeight * CGFloat(maxLines)
            height = min(height, ceil(cap))
        }
        return height
    }
}
