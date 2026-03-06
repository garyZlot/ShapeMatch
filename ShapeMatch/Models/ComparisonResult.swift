//
//  ComparisonResult.swift
//  ShapeMatch
//
//  图片对比结果数据模型
//

import SwiftUI
import CoreGraphics

struct DifferencePoint: Identifiable {
    let id = UUID()
    let location: CGPoint       // 差异点位置（归一化坐标 0-1）
    let size: CGFloat           // 差异区域大小
    let intensity: CGFloat      // 差异强度 0-1
}

struct ComparisonResult {
    let leftImage: UIImage?
    let rightImage: UIImage?
    let differences: [DifferencePoint]
    let similarity: CGFloat     // 相似度 0-1
    let processTime: TimeInterval

    var hasDifferences: Bool {
        !differences.isEmpty
    }
}
