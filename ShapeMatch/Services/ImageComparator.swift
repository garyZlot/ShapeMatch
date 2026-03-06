//
//  ImageComparator.swift
//  ShapeMatch
//
//  图片对比服务 - 核心对比算法实现
//

import UIKit
import CoreImage
import Accelerate

struct ImageComparator {

    // MARK: - 主对比方法
    func compare(_ image1: UIImage, with image2: UIImage) async throws -> ComparisonResult {
        let startTime = Date()

        // 1. 预处理图片（调整大小、统一尺寸）
        let (processed1, processed2) = try await preprocessImages(image1, image2)

        // 2. 执行差异检测
        let differences = try await detectDifferences(
            leftImage: processed1,
            rightImage: processed2
        )

        // 3. 计算相似度
        let similarity = calculateSimilarity(
            leftImage: processed1,
            rightImage: processed2,
            differenceCount: differences.count
        )

        let processTime = Date().timeIntervalSince(startTime)

        return ComparisonResult(
            leftImage: image1,
            rightImage: image2,
            differences: differences,
            similarity: similarity,
            processTime: processTime
        )
    }

    // MARK: - 图片预处理
    private func preprocessImages(_ image1: UIImage, _ image2: UIImage) async throws -> (UIImage, UIImage) {
        // 统一图片尺寸（取较小的尺寸）
        let targetSize = CGSize(
            width: min(image1.size.width, image2.size.width, 800),
            height: min(image1.size.height, image2.size.height, 800)
        )

        let processed1 = resizeImage(image1, to: targetSize)
        let processed2 = resizeImage(image2, to: targetSize)

        return (processed1, processed2)
    }

    // MARK: - 差异检测（核心算法）
    private func detectDifferences(leftImage: UIImage, rightImage: UIImage) async throws -> [DifferencePoint] {
        guard let leftData = leftImage.pngData(),
              let rightData = rightImage.pngData() else {
            throw ComparisonError.invalidImageData
        }

        guard let leftCIImage = CIImage(data: leftData),
              let rightCIImage = CIImage(data: rightData) else {
            throw ComparisonError.invalidImageData
        }

        // 获取像素数据进行对比
        guard let leftPixels = getPixelData(from: leftImage),
              let rightPixels = getPixelData(from: rightImage) else {
            throw ComparisonError.invalidImageData
        }

        let width = Int(leftImage.size.width)
        let height = Int(leftImage.size.height)

        // 使用 Accelerate 框架加速像素对比
        var differences: [DifferencePoint] = []
        let threshold: UInt8 = 30 // 差异阈值

        // 分块处理以提高性能
        let blockSize = 16
        for y in stride(from: 0, to: height - blockSize, by: blockSize) {
            for x in stride(from: 0, to: width - blockSize, by: blockSize) {
                var blockDifference: UInt32 = 0

                // 计算块内的差异
                for by in 0..<blockSize {
                    for bx in 0..<blockSize {
                        let idx1 = ((y + by) * width + (x + bx)) * 4
                        let idx2 = idx1

                        let rDiff = abs(Int(leftPixels[idx1]) - Int(rightPixels[idx2]))
                        let gDiff = abs(Int(leftPixels[idx1 + 1]) - Int(rightPixels[idx2 + 1]))
                        let bDiff = abs(Int(leftPixels[idx1 + 2]) - Int(rightPixels[idx2 + 2]))

                        let totalDiff = (rDiff + gDiff + bDiff) / 3
                        if totalDiff > Int(threshold) {
                            blockDifference += 1
                        }
                    }
                }

                // 如果块内差异超过阈值，记录差异点
                let totalPixels = blockSize * blockSize
                let differenceRatio = Float(blockDifference) / Float(totalPixels)

                if differenceRatio > 0.3 { // 30% 的像素有差异
                    let centerX = Float(x + blockSize / 2) / Float(width)
                    let centerY = Float(y + blockSize / 2) / Float(height)

                    let diffPoint = DifferencePoint(
                        location: CGPoint(x: CGFloat(centerX), y: CGFloat(centerY)),
                        size: CGFloat(blockSize * 2),
                        intensity: CGFloat(differenceRatio)
                    )
                    differences.append(diffPoint)
                }
            }
        }

        // 合并相近的差异点
        return mergeNearbyDifferences(differences)
    }

    // MARK: - 合并相近的差异点
    private func mergeNearbyDifferences(_ differences: [DifferencePoint]) -> [DifferencePoint] {
        var merged: [DifferencePoint] = []
        var processed = Set<Int>()

        for (i, diff) in differences.enumerated() {
            if processed.contains(i) { continue }

            var nearbyDiffs: [DifferencePoint] = [diff]
            processed.insert(i)

            // 查找附近的差异点
            for (j, other) in differences.enumerated() {
                if i == j || processed.contains(j) { continue }

                let distance = sqrt(
                    pow(diff.location.x - other.location.x, 2) +
                    pow(diff.location.y - other.location.y, 2)
                )

                if distance < 0.1 { // 距离小于 10% 视为同一区域
                    nearbyDiffs.append(other)
                    processed.insert(j)
                }
            }

            // 计算合并后的中心点和强度
            let avgX = nearbyDiffs.reduce(0.0) { $0 + $1.location.x } / CGFloat(nearbyDiffs.count)
            let avgY = nearbyDiffs.reduce(0.0) { $0 + $1.location.y } / CGFloat(nearbyDiffs.count)
            let avgIntensity = nearbyDiffs.reduce(0.0) { $0 + $1.intensity } / CGFloat(nearbyDiffs.count)
            let maxSize = nearbyDiffs.map { $0.size }.max() ?? diff.size

            let mergedDiff = DifferencePoint(
                location: CGPoint(x: avgX, y: avgY),
                size: maxSize,
                intensity: avgIntensity
            )
            merged.append(mergedDiff)
        }

        return merged
    }

    // MARK: - 计算相似度
    private func calculateSimilarity(
        leftImage: UIImage,
        rightImage: UIImage,
        differenceCount: Int
    ) -> CGFloat {
        // 基础相似度（基于差异点数量）
        let maxDifferences = 50 // 假设最大差异点数
        let baseSimilarity = 1.0 - (CGFloat(differenceCount) / CGFloat(maxDifferences))

        return max(0.0, min(1.0, baseSimilarity))
    }

    // MARK: - 工具方法：调整图片大小
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return resizedImage
    }

    // MARK: - 工具方法：获取像素数据
    private func getPixelData(from image: UIImage) -> [UInt8]? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        guard let imageData = CFDataCreateMutable(nil, width * height * bytesPerPixel),
              let context = CGContext(
                data: CFDataGetMutableBytePtr(imageData),
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixels = CFDataGetBytePtr(imageData) else { return nil }

        return Array(UnsafeBufferPointer(start: pixels, count: width * height * bytesPerPixel))
    }
}

// MARK: - 错误类型
enum ComparisonError: LocalizedError {
    case invalidImageData
    case sizeMismatch
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "无法读取图片数据"
        case .sizeMismatch:
            return "图片尺寸不匹配"
        case .processingFailed:
            return "图片处理失败"
        }
    }
}
