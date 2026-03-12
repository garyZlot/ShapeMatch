//
//  Layer.swift
//  ShapeMatch
//
//  图层数据模型
//

import SwiftUI

struct Layer: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let image: UIImage
    var position: CGSize
    var scale: CGFloat
    var opacity: Double
    var isVisible: Bool
    var isLocked: Bool
    var rotation: Double  // 旋转角度（度）

    init(
        name: String,
        image: UIImage,
        position: CGSize = .zero,
        scale: CGFloat = 1.0,
        opacity: Double = 1.0,
        isVisible: Bool = true,
        isLocked: Bool = false,
        rotation: Double = 0.0
    ) {
        self.name = name
        self.image = image
        self.position = position
        self.scale = scale
        self.opacity = opacity
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.rotation = rotation
    }

    // Equatable 实现
    static func == (lhs: Layer, rhs: Layer) -> Bool {
        return lhs.id == rhs.id &&
               lhs.position == rhs.position &&
               lhs.scale == rhs.scale &&
               lhs.opacity == rhs.opacity &&
               lhs.isVisible == rhs.isVisible &&
               lhs.isLocked == rhs.isLocked &&
               lhs.rotation == rhs.rotation
    }
}
