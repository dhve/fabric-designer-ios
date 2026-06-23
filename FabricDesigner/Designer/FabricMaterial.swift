import SceneKit
import UIKit
import CoreGraphics

/// PBR material factory — maps each of the 15 `FabricType`s onto a tuned
/// `SCNMaterial`. Mirrors the React project's `fabricTextures.ts`.
///
/// Two procedural texture types are generated on demand and cached:
///   * Twill diagonal pattern (denim)
///   * Plain micro-weave (linen, cotton, jersey)
public enum FabricMaterial {
    private static var normalCache: [String: UIImage] = [:]

    public static func make(for fabric: FabricType, colorHex: String) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.locksAmbientWithDiffuse = true

        let base = UIColor(hex: colorHex) ?? .gray
        m.diffuse.contents = base

        switch fabric {
        case .silk:
            m.roughness.contents = 0.18
            m.metalness.contents = 0.05
            m.clearCoat.contents = 0.35
            m.clearCoatRoughness.contents = 0.10
        case .satin:
            m.roughness.contents = 0.12
            m.metalness.contents = 0.20
            m.clearCoat.contents = 0.55
            m.clearCoatRoughness.contents = 0.05
        case .velvet:
            m.roughness.contents = 0.95
            m.metalness.contents = 0.0
            m.emission.contents = base.darkened(by: 0.55)
            m.emission.intensity = 0.18
        case .chiffon:
            m.roughness.contents = 0.55
            m.metalness.contents = 0.0
            m.transparency = 0.78
            m.transparencyMode = .dualLayer
        case .cashmere:
            m.roughness.contents = 0.80
            m.metalness.contents = 0.0
            m.fresnelExponent = 1.8
        case .cotton:
            m.roughness.contents = 0.85
            m.metalness.contents = 0.0
            m.normal.contents = microWeaveNormal()
            m.normal.intensity = 0.25
        case .linen:
            m.roughness.contents = 0.92
            m.metalness.contents = 0.0
            m.normal.contents = microWeaveNormal()
            m.normal.intensity = 0.40
        case .jersey:
            m.roughness.contents = 0.78
            m.metalness.contents = 0.0
            m.normal.contents = microWeaveNormal()
            m.normal.intensity = 0.18
        case .polyester:
            m.roughness.contents = 0.45
            m.metalness.contents = 0.05
            m.clearCoat.contents = 0.10
        case .canvas:
            m.roughness.contents = 0.95
            m.metalness.contents = 0.0
            m.normal.contents = microWeaveNormal()
            m.normal.intensity = 0.55
        case .denim:
            m.roughness.contents = 0.78
            m.metalness.contents = 0.0
            m.normal.contents = twillNormal()
            m.normal.intensity = 0.55
        case .tweed:
            m.roughness.contents = 0.85
            m.metalness.contents = 0.0
            m.normal.contents = twillNormal()
            m.normal.intensity = 0.70
        case .wool:
            m.roughness.contents = 0.80
            m.metalness.contents = 0.0
            m.fresnelExponent = 2.4
        case .leather:
            m.roughness.contents = 0.45
            m.metalness.contents = 0.0
            m.clearCoat.contents = 0.40
            m.clearCoatRoughness.contents = 0.25
        case .suede:
            m.roughness.contents = 0.85
            m.metalness.contents = 0.0
            m.fresnelExponent = 1.4
        }
        return m
    }

    // MARK: - Procedural normal maps

    private static func twillNormal(size: Int = 128) -> UIImage {
        let key = "twill-\(size)"
        if let cached = normalCache[key] { return cached }
        let img = renderNormalMap(size: size) { x, y in
            // Diagonal stripes → tangent-space normal that perturbs along (1, -1).
            let diag = (x + y).truncatingRemainder(dividingBy: 6.0)
            let v = sin(diag * .pi / 3.0)
            // Encode normal: (nx, ny, nz) → RGB (0..1)
            let nx = 0.5 + 0.25 * v
            let ny = 0.5 + 0.25 * v
            return (nx, ny, 1.0)
        }
        normalCache[key] = img
        return img
    }

    private static func microWeaveNormal(size: Int = 128) -> UIImage {
        let key = "weave-\(size)"
        if let cached = normalCache[key] { return cached }
        let img = renderNormalMap(size: size) { x, y in
            let u = sin(x * .pi / 2.0) * 0.5 + 0.5
            let v = sin(y * .pi / 2.0) * 0.5 + 0.5
            return (0.5 + 0.08 * (u - 0.5), 0.5 + 0.08 * (v - 0.5), 1.0)
        }
        normalCache[key] = img
        return img
    }

    private static func renderNormalMap(size: Int, sample: (Double, Double) -> (Double, Double, Double)) -> UIImage {
        let bytesPerRow = size * 4
        var pixels = [UInt8](repeating: 0, count: size * bytesPerRow)
        for y in 0..<size {
            for x in 0..<size {
                let (nx, ny, nz) = sample(Double(x), Double(y))
                let i = (y * size + x) * 4
                pixels[i + 0] = UInt8(max(0, min(255, nx * 255)))
                pixels[i + 1] = UInt8(max(0, min(255, ny * 255)))
                pixels[i + 2] = UInt8(max(0, min(255, nz * 255)))
                pixels[i + 3] = 255
            }
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(
            data: &pixels,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ), let cg = ctx.makeImage() else {
            return UIImage()
        }
        return UIImage(cgImage: cg)
    }
}

// MARK: - UIColor helpers

extension UIColor {
    convenience init?(hex: String) {
        var s = hex.replacingOccurrences(of: "#", with: "")
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        let r = CGFloat((v >> 16) & 0xFF) / 255.0
        let g = CGFloat((v >>  8) & 0xFF) / 255.0
        let b = CGFloat( v        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }

    func darkened(by amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(
            red: max(0, r - amount),
            green: max(0, g - amount),
            blue: max(0, b - amount),
            alpha: a
        )
    }
}
