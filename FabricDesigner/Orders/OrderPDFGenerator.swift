import Foundation
import UIKit

public enum OrderPDFGenerator {
    public static func generate(order: Order, to directory: URL = FileManager.default.temporaryDirectory) throws -> URL {
        let fileURL = directory.appendingPathComponent("atelier-order-\(order.id).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        try renderer.writePDF(to: fileURL) { context in
            context.beginPage()
            var cursor: CGFloat = 36
            let margin: CGFloat = 42
            let width: CGFloat = 612 - margin * 2

            drawHeader(order: order, x: margin, y: &cursor, width: width)
            drawSection("Customer / Shipping", rows: shippingRows(order.shipping), context: context, x: margin, y: &cursor, width: width)
            drawSection("Measurements", rows: measurementRows(order.measurements), context: context, x: margin, y: &cursor, width: width)
            drawSection("Outfit / Fabric", rows: outfitRows(order.outfit), context: context, x: margin, y: &cursor, width: width)
            drawSection("Payment Record", rows: paymentRows(order), context: context, x: margin, y: &cursor, width: width)
            drawSection("Notes / Reference Photos", rows: notesRows(order), context: context, x: margin, y: &cursor, width: width)
        }

        return fileURL
    }

    private static func drawHeader(order: Order, x: CGFloat, y: inout CGFloat, width: CGFloat) {
        draw("Atelier Fabric Designer Order Sheet", at: CGPoint(x: x, y: y), width: width, font: .boldSystemFont(ofSize: 22))
        y += 30
        draw("Order ID: \(order.id)", at: CGPoint(x: x, y: y), width: width, font: .systemFont(ofSize: 10))
        y += 15
        draw("Created: \(Self.dateFormatter.string(from: order.createdAt))", at: CGPoint(x: x, y: y), width: width, font: .systemFont(ofSize: 10))
        y += 28
    }

    private static func drawSection(_ title: String, rows: [(String, String)], context: UIGraphicsPDFRendererContext, x: CGFloat, y: inout CGFloat, width: CGFloat) {
        if y > 700 {
            context.beginPage()
            y = 36
        }

        draw(title.uppercased(), at: CGPoint(x: x, y: y), width: width, font: .boldSystemFont(ofSize: 12))
        y += 17

        for row in rows {
            let labelWidth: CGFloat = 165
            draw(row.0, at: CGPoint(x: x, y: y), width: labelWidth, font: .boldSystemFont(ofSize: 9), color: .darkGray)
            let textHeight = draw(row.1.isEmpty ? "-" : row.1, at: CGPoint(x: x + labelWidth, y: y), width: width - labelWidth, font: .systemFont(ofSize: 9))
            y += max(14, textHeight + 3)
            if y > 740 {
                context.beginPage()
                y = 36
            }
        }

        y += 12
    }

    @discardableResult
    private static func draw(_ text: String, at point: CGPoint, width: CGFloat, font: UIFont, color: UIColor = .black) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let rect = CGRect(x: point.x, y: point.y, width: width, height: 120)
        let height = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).height
        (text as NSString).draw(in: rect, withAttributes: attributes)
        return ceil(height)
    }

    private static func shippingRows(_ shipping: ShippingInfo) -> [(String, String)] {
        [
            ("Customer", shipping.fullName),
            ("Address 1", shipping.line1),
            ("Address 2", shipping.line2),
            ("City / Region / Postal", "\(shipping.city), \(shipping.region) \(shipping.postalCode)"),
            ("Country", shipping.country),
            ("Shipping / fit notes", shipping.notes)
        ]
    }

    private static func measurementRows(_ measurements: BodyMeasurements?) -> [(String, String)] {
        guard let m = measurements else {
            return [("Status", "No measurements attached")]
        }

        let values: [(String, Double)] = [
            ("Height", m.heightCM),
            ("Shoulder", m.shoulderWidthCM),
            ("Sleeve", m.sleeveLengthCM),
            ("Chest", m.chestCircumferenceCM),
            ("Waist", m.waistCircumferenceCM),
            ("Hip", m.hipCircumferenceCM),
            ("Inseam", m.inseamCM),
            ("Neck", m.neckCircumferenceCM),
            ("Thigh", m.thighCircumferenceCM)
        ]

        return [
            ("Source", m.source.displayName),
            ("Confidence", "\(Int(m.confidence * 100))%"),
            ("Captured", Self.dateFormatter.string(from: m.capturedAt))
        ] + values.map { ($0.0, String(format: "%.1f cm / %.1f in", $0.1, $0.1 / 2.54)) }
    }

    private static func outfitRows(_ outfit: Outfit) -> [(String, String)] {
        outfit.items.enumerated().map { index, garment in
            (
                "Item \(index + 1)",
                "\(garment.name) | \(garment.category.displayName) | \(garment.fabricType.displayName) | \(garment.colorName) \(garment.colorHex) | Size \(garment.size ?? "-")"
            )
        }
    }

    private static func paymentRows(_ order: Order) -> [(String, String)] {
        [
            ("Method", order.paymentMethod.displayName),
            ("Base price", String(format: "$%.2f", order.basePriceUSD)),
            ("Total price", String(format: "$%.2f", order.totalUSD)),
            ("Payment status", order.paymentStatus.displayName),
            ("Crypto network", order.cryptoNetwork),
            ("Wallet / receiving account", order.receivingAccount),
            ("Transaction hash", order.transactionHash),
            ("Cash / trade verification", order.paymentVerificationNote)
        ]
    }

    private static func notesRows(_ order: Order) -> [(String, String)] {
        [
            ("Reference photo count", "\(order.photoCount)"),
            ("Designer notes", order.designerNotes)
        ]
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
