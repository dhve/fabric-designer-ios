import Foundation

/// Default 12-piece garment catalog, identical in shape to the React app's
/// `outfit/catalog.ts`. Used as the fallback wardrobe before the user adds
/// anything of their own and as the seed dataset for the wardrobe store.
public enum Catalog {
    public static let `default`: [Garment] = [
        // Tops
        Garment(id: "top-1", name: "Oxford Shirt",       category: .top,       fabricType: .cotton, colorHex: "#e8e0d5", colorName: "Cream"),
        Garment(id: "top-2", name: "Silk Blouse",         category: .top,       fabricType: .silk,   colorHex: "#2c3e50", colorName: "Midnight"),
        Garment(id: "top-3", name: "Denim Jacket",        category: .top,       fabricType: .denim,  colorHex: "#4a6fa5", colorName: "Indigo"),
        Garment(id: "top-4", name: "Cashmere Crewneck",   category: .top,       fabricType: .cashmere, colorHex: "#d4b89a", colorName: "Camel"),

        // Bottoms
        Garment(id: "bottom-1", name: "Linen Trousers",   category: .bottom,    fabricType: .linen,  colorHex: "#c9b99a", colorName: "Sand"),
        Garment(id: "bottom-2", name: "Silk Skirt",       category: .bottom,    fabricType: .silk,   colorHex: "#8b5e83", colorName: "Plum"),
        Garment(id: "bottom-3", name: "Raw Denim Jeans",  category: .bottom,    fabricType: .denim,  colorHex: "#1c2c4c", colorName: "Indigo"),
        Garment(id: "bottom-4", name: "Velvet Pants",     category: .bottom,    fabricType: .velvet, colorHex: "#6b3e8e", colorName: "Iris"),

        // Shoes
        Garment(id: "shoes-1", name: "Canvas Sneakers",   category: .shoes,     fabricType: .canvas, colorHex: "#f5f5f0", colorName: "Off White"),
        Garment(id: "shoes-2", name: "Leather Loafers",   category: .shoes,     fabricType: .leather, colorHex: "#2d2d2d", colorName: "Onyx"),
        Garment(id: "shoes-3", name: "Suede Boots",       category: .shoes,     fabricType: .suede,  colorHex: "#5c3d2e", colorName: "Walnut"),

        // Outerwear
        Garment(id: "outer-1", name: "Cotton Trench",     category: .outerwear, fabricType: .cotton, colorHex: "#c8a882", colorName: "Camel"),
        Garment(id: "outer-2", name: "Tweed Blazer",      category: .outerwear, fabricType: .tweed,  colorHex: "#4a4a4a", colorName: "Charcoal"),
        Garment(id: "outer-3", name: "Silk Evening Coat", category: .outerwear, fabricType: .silk,   colorHex: "#1a1a2e", colorName: "Midnight Navy"),
        Garment(id: "outer-4", name: "Wool Overcoat",     category: .outerwear, fabricType: .wool,   colorHex: "#8b6b5b", colorName: "Earth"),
    ]
}
