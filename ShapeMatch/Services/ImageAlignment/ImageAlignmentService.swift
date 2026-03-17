//
//  ImageAlignmentService.swift
//  ShapeMatch
//
//  图像对齐服务 - 提供统一的接口和算法管理
//

import UIKit
import SwiftUI
import Combine

/// 图像对齐服务
final class ImageAlignmentService: ObservableObject {

    // MARK: - Singleton

    static let shared = ImageAlignmentService()

    // MARK: - Properties

    /// 当前使用的对齐算法
    private let alignmentAlgorithm: ImageAlignmentProtocol

    /// 是否正在处理
    private var _isProcessing = false

    public var isProcessing: Bool {
        _isProcessing
    }

    /// 处理进度（0-1）
    private var _progress: Double = 0

    public var progress: Double {
        _progress
    }

    /// 当前使用的算法名称
    var currentAlgorithmName: String {
        alignmentAlgorithm.algorithmName
    }

    // MARK: - Initialization

    private init(algorithm: ImageAlignmentProtocol? = nil) {
        // 默认使用 Vision 算法
        self.alignmentAlgorithm = algorithm ?? VisionImageAlignment()
    }

    // MARK: - Public Methods

    /// 切换对齐算法（便于测试和替换）
    func setAlgorithm(_ algorithm: ImageAlignmentProtocol) {
        // 取消当前操作
        cancel()

        // 注意：这里不能直接修改 alignmentAlgorithm 因为它是 let
        // 如果需要动态切换，应该使用 var 或者在初始化时传入
        print("⚠️ 当前实现不支持动态切换算法")
    }

    /// 执行图像对齐
    /// - Parameters:
    ///   - sourceImage: 源图片（需要被移动的图片）
    ///   - targetImage: 目标图片（参考图片）
    ///   - completion: 完成回调
    func align(
        sourceImage: UIImage,
        targetImage: UIImage,
        completion: @escaping (Result<ImageTransform, Error>) -> Void
    ) {
        // 取消之前的操作
        cancel()

        // 在主线程更新状态
        DispatchQueue.main.async { [weak self] in
            self?._isProcessing = true
            self?._progress = 0
            self?.objectWillChange.send()
        }

        // 执行对齐
        alignmentAlgorithm.align(
            sourceImage: sourceImage,
            targetImage: targetImage
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?._isProcessing = false
                self?._progress = 1.0
                self?.objectWillChange.send()
                completion(result)
            }
        }
    }

    /// 取消当前操作
    func cancel() {
        alignmentAlgorithm.cancel()
        _isProcessing = false
        _progress = 0

        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }

    // MARK: - Convenience Methods

    /// 快速对齐两个图层（直接应用到图层）
    func alignLayer(
        sourceLayer: Layer,
        targetImage: UIImage,
        completion: @escaping (Result<Layer, Error>) -> Void
    ) {
        let sourceImage = sourceLayer.image
        align(sourceImage: sourceImage, targetImage: targetImage) { result in
            switch result {
            case .success(let transform):
                // 应用变换到图层
                let alignedLayer = Layer(
                    name: sourceLayer.name,
                    image: sourceLayer.image,
                    position: transform.translation,
                    scale: transform.scale,
                    opacity: sourceLayer.opacity,
                    isVisible: sourceLayer.isVisible,
                    isLocked: sourceLayer.isLocked,
                    rotation: transform.rotation
                )
                completion(.success(alignedLayer))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
