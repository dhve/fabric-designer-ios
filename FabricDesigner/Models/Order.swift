import Foundation

/// Multi-tender checkout — mirrors the PRD's "electronic transfer, cash,
/// crypto, or another verified store of value (such as gold) in a
/// traditional truck/barter/trade commercial style". Credit cards are
/// accepted but flagged with a 110% restocking-fee notice per the PRD.
public enum PaymentMethod: String, CaseIterable, Codable, Identifiable, Sendable {
    case electronicTransfer
    case cash
    case crypto
    case storeOfValue       // gold, silver, barter
    case creditCard

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .electronicTransfer: return "Electronic Transfer"
        case .cash:               return "Cash"
        case .crypto:             return "Crypto / Web3"
        case .storeOfValue:       return "Gold · Barter"
        case .creditCard:         return "Credit Card"
        }
    }

    public var icon: String {
        switch self {
        case .electronicTransfer: return "arrow.left.arrow.right.square"
        case .cash:               return "dollarsign.circle"
        case .crypto:             return "bitcoinsign.circle"
        case .storeOfValue:       return "shield.lefthalf.filled"
        case .creditCard:         return "creditcard"
        }
    }

    public var subtitle: String {
        switch self {
        case .electronicTransfer: return "ACH · SEPA · UPI"
        case .cash:               return "Bills, IRL handoff"
        case .crypto:             return "ETH · BTC · USDC"
        case .storeOfValue:       return "Truck · Barter · Trade"
        case .creditCard:         return "Visa · MC · AmEx"
        }
    }

    /// 1.0 = no surcharge. Credit cards carry the 110% return restocking
    /// fee from the PRD, surfaced in the checkout UI before confirmation.
    public var restockingMultiplier: Double {
        self == .creditCard ? 1.10 : 1.00
    }

    public var carriesRestockingNotice: Bool { self == .creditCard }
}

public struct ShippingInfo: Codable, Hashable, Sendable {
    public var fullName: String = ""
    public var line1: String = ""
    public var line2: String = ""
    public var city: String = ""
    public var region: String = ""
    public var postalCode: String = ""
    public var country: String = ""
    public var notes: String = ""

    public var isComplete: Bool {
        !fullName.isEmpty && !line1.isEmpty && !city.isEmpty && !postalCode.isEmpty
    }
}

public struct Order: Codable, Hashable, Sendable {
    public var outfit: Outfit
    public var measurements: BodyMeasurements?
    public var photoCount: Int
    public var designerNotes: String
    public var paymentMethod: PaymentMethod
    public var shipping: ShippingInfo
    public var basePriceUSD: Double
    public var createdAt: Date

    public var totalUSD: Double {
        basePriceUSD * paymentMethod.restockingMultiplier
    }

    public init(
        outfit: Outfit,
        measurements: BodyMeasurements?,
        photoCount: Int,
        designerNotes: String,
        paymentMethod: PaymentMethod,
        shipping: ShippingInfo,
        basePriceUSD: Double,
        createdAt: Date = Date()
    ) {
        self.outfit = outfit
        self.measurements = measurements
        self.photoCount = photoCount
        self.designerNotes = designerNotes
        self.paymentMethod = paymentMethod
        self.shipping = shipping
        self.basePriceUSD = basePriceUSD
        self.createdAt = createdAt
    }
}
