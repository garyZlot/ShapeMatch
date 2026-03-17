//
//  ImageAlignmentProtocol.swift
//  ShapeMatch
//
//  图像对齐协议 - 定义自动对齐接口，便于替换不同算法
//

import UIKit
import SwiftUI

// MARK: - 对齐结果

/// 图像对齐变换参数
struct ImageTransform: Codable {
    /// 平移量（CGPoint: x, y）
    let translation: CGSize

    /// 缩放比例
    let scale: CGFloat

    /// 旋转角度（弧度）
    let rotation: CGFloat

    /// 置信度（0-1，越高越可信）
    let confidence: CGFloat

    /// 匹配的特征点数量
    let matchCount: Int

    /// 创建默认变换
    static var identity: ImageTransform {
        ImageTransform(
            translation: .zero,
            scale: 1.0,
            rotation: 0.0,
            confidence: 0.0,
            matchCount: 0
        )
    }

    /// 是否为有效变换（置信度足够高）
    var isValid: Bool {
        confidence >= 0.7 // 阈值可调整
    }
}

// MARK: - 对齐协议

/// 图像对齐算法协议
protocol ImageAlignmentProtocol {
    /// 算法名称（用于UI显示）
    var algorithmName: String { get }

    /// 对齐两张图片
    /// - Parameters:
    ///   - sourceImage: 源图片（需要被移动的图片，通常是顶层图）
    ///   - targetImage: 目标图片（参考图片，通常是底层图）
    ///   - completion: 完成回调，返回变换参数或错误
    func align(
        sourceImage: UIImage,
        targetImage: UIImage,
        completion: @escaping (Result<ImageTransform, Error>) -> Void
    )

    /// 取消当前对齐操作（如果支持）
    func cancel()
}

// MARK: - 对齐错误

enum ImageAlignmentError: LocalizedError {
    case insufficientFeaturePoints
    case lowConfidence(CGFloat)
    case processingFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .insufficientFeaturePoints:
            return "未能找到足够的特征点，建议使用手动对齐"
        case .lowConfidence(let confidence):
            return "对齐置信度过低(\(String(format: "%.1f%%", confidence * 100)))，建议使用手动对齐"
        case .processingFailed(let reason):
            return "对齐失败: \(reason)"
        case .cancelled:
            return "已取消"
        }
    }
}
