//
//  VisionImageAlignment.swift
//  ShapeMatch
//
//  基于像素相关的图像对齐实现
//

import UIKit
import Accelerate
import CoreGraphics

/// 基于像素相关的图像对齐
final class VisionImageAlignment: ImageAlignmentProtocol {

    let algorithmName = "像素匹配算法"

    private var isCancelled = false

    // MARK: - ImageAlignmentProtocol

    func align(
        sourceImage: UIImage,
        targetImage: UIImage,
        completion: @escaping (Result<ImageTransform, Error>) -> Void
    ) {
        isCancelled = false

        print("🔄 开始图像对齐...")
        print("   源图片尺寸: \(sourceImage.size)")
        print("   目标图片尺寸: \(targetImage.size)")

        // 在后台队列执行
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, !self.isCancelled else {
                print("❌ 对齐被取消")
                DispatchQueue.main.async {
                    completion(.failure(ImageAlignmentError.cancelled))
                }
                return
            }

            // 检查 CGImage 是否可用
            guard let targetCGImage = targetImage.cgImage,
                  let sourceCGImage = sourceImage.cgImage else {
                print("❌ 无法获取图片数据")
                DispatchQueue.main.async {
                    completion(.failure(ImageAlignmentError.processingFailed("无法获取图片数据")))
                }
                return
            }

            // 缩小图片尺寸以加快计算速度
            let scale: CGFloat = 0.125 // 缩小到 12.5%（更快）
            print("🔽 缩小图片到 \(Int(scale * 100))%")

            guard let scaledTarget = self.resizeImage(targetCGImage, scale: scale),
                  let scaledSource = self.resizeImage(sourceCGImage, scale: scale) else {
                print("❌ 图片处理失败")
                DispatchQueue.main.async {
                    completion(.failure(ImageAlignmentError.processingFailed("图片处理失败")))
                }
                return
            }

            print("✅ 图片缩放完成，开始匹配...")

            // 使用模板匹配找出最佳位置
            let startTime = CFAbsoluteTimeGetCurrent()
            let result = self.findBestMatch(
                source: scaledSource,
                target: scaledTarget
            )
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime

            print("⏱️ 匹配耗时: \(String(format: "%.2f", elapsed))秒")

            if self.isCancelled {
                print("❌ 对齐被取消")
                DispatchQueue.main.async {
                    completion(.failure(ImageAlignmentError.cancelled))
                }
                return
            }

            // 将结果缩放回原始尺寸
            let scaledTranslation = CGSize(
                width: result.translation.width / scale,
                height: result.translation.height / scale
            )

            print("🔍 对齐结果:")
            print("   缩放后偏移: x=\(result.translation.width), y=\(result.translation.height)")
            print("   原始偏移: x=\(scaledTranslation.width), y=\(scaledTranslation.height)")
            print("   相关系数: \(result.correlation)")

            // 检查相关性阈值
            guard result.correlation >= 0.2 else {
                print("❌ 置信度太低: \(result.correlation)")
                DispatchQueue.main.async {
                    completion(.failure(ImageAlignmentError.lowConfidence(result.correlation)))
                }
                return
            }

            print("✅ 对齐成功！")

            // 创建变换结果
            let transform = ImageTransform(
                translation: scaledTranslation,
                scale: 1.0,
                rotation: 0.0,
                confidence: result.correlation,
                matchCount: 0
            )

            DispatchQueue.main.async {
                completion(.success(transform))
            }
        }
    }

    func cancel() {
        isCancelled = true
    }

    // MARK: - Private Methods

    /// 匹配结果
    private struct MatchResult {
        let translation: CGSize
        let correlation: CGFloat
    }

    /// 缩放图片
    private func resizeImage(_ image: CGImage, scale: CGFloat) -> CGImage? {
        let width = Int(CGFloat(image.width) * scale)
        let height = Int(CGFloat(image.height) * scale)

        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        context?.interpolationQuality = .high
        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context?.makeImage()
    }

    /// 使用归一化互相关找到最佳匹配位置
    private func findBestMatch(source: CGImage, target: CGImage) -> MatchResult {
        // 获取图片数据
        guard let sourceData = getImageData(source),
              let targetData = getImageData(target) else {
            print("❌ 无法获取图片数据")
            return MatchResult(translation: .zero, correlation: 0)
        }

        let sourceWidth = source.width
        let sourceHeight = source.height
        let targetWidth = target.width
        let targetHeight = target.height

        // 限制搜索范围（假设偏移不会超过图片尺寸的 15%）
        let searchRangeX = min(targetWidth / 7, 50)
        let searchRangeY = min(targetHeight / 7, 50)

        print("   搜索范围: ±\(searchRangeX)x±\(searchRangeY)")

        var bestOffset: CGSize = .zero
        var bestCorrelation: CGFloat = -1

        // 暴力搜索最佳位置
        // 注意：这是简化版本，实际应该使用 FFT 加速
        let step = 3 // 跳步采样以提高速度（从2改为3）
        var iterations = 0

        for dy in -searchRangeY...searchRangeY where dy % step == 0 {
            for dx in -searchRangeX...searchRangeX where dx % step == 0 {
                iterations += 1
                let correlation = calculateCorrelation(
                    sourceData: sourceData,
                    targetData: targetData,
                    sourceWidth: sourceWidth,
                    sourceHeight: sourceHeight,
                    targetWidth: targetWidth,
                    targetHeight: targetHeight,
                    offsetX: dx,
                    offsetY: dy
                )

                if correlation > bestCorrelation {
                    bestCorrelation = correlation
                    bestOffset = CGSize(width: dx, height: dy)
                }
            }
        }

        print("   完成了 \(iterations) 次迭代")
        print("   最佳偏移: (\(bestOffset.width), \(bestOffset.height))")

        return MatchResult(translation: bestOffset, correlation: bestCorrelation)
    }

    /// 计算两个图片区域在给定偏移下的相关系数
    private func calculateCorrelation(
        sourceData: [UInt8],
        targetData: [UInt8],
        sourceWidth: Int,
        sourceHeight: Int,
        targetWidth: Int,
        targetHeight: Int,
        offsetX: Int,
        offsetY: Int
    ) -> CGFloat {
        var sum: Double = 0
        var count = 0

        // 计算重叠区域
        let startX = max(0, -offsetX)
        let startY = max(0, -offsetY)
        let endX = min(sourceWidth, targetWidth - offsetX)
        let endY = min(sourceHeight, targetHeight - offsetY)

        // 计算重叠区域的像素差异
        for y in startY..<endY {
            for x in startX..<endX {
                let sourceIdx = (y * sourceWidth + x) * 4
                let targetX = x + offsetX
                let targetY = y + offsetY
                let targetIdx = (targetY * targetWidth + targetX) * 4

                // 简单的 RGB 差异计算
                let rDiff = Double(sourceData[sourceIdx]) - Double(targetData[targetIdx])
                let gDiff = Double(sourceData[sourceIdx + 1]) - Double(targetData[targetIdx + 1])
                let bDiff = Double(sourceData[sourceIdx + 2]) - Double(targetData[targetIdx + 2])

                let diff = sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff)
                sum += diff
                count += 1
            }
        }

        // 转换为相关系数（差异越小，相关性越高）
        let avgDiff = count > 0 ? sum / Double(count) : 255
        let maxDiff = 255.0 * sqrt(3.0)
        let correlation = 1.0 - (avgDiff / maxDiff)

        return correlation
    }

    /// 获取图片的像素数据
    private func getImageData(_ image: CGImage) -> [UInt8]? {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        let totalBytes = height * bytesPerRow

        var pixelData = [UInt8](repeating: 0, count: totalBytes)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        return pixelData
    }
}
