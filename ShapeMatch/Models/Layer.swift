//
//  Layer.swift
//  ShapeMatch
//
//  图层数据模型
//

import SwiftUI

struct Layer: Identifiable {
    let id = UUID()
    let name: String
    let image: UIImage
    var position: CGSize
    var scale: CGFloat
    var opacity: Double
    var isVisible: Bool

    init(
        name: String,
        image: UIImage,
        position: CGSize = .zero,
        scale: CGFloat = 1.0,
        opacity: Double = 1.0,
        isVisible: Bool = true
    ) {
        self.name = name
        self.image = image
        self.position = position
        self.scale = scale
        self.opacity = opacity
        self.isVisible = isVisible
    }
}
