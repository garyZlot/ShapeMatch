//
//  ComparisonViewModel.swift
//  ShapeMatch
//
//  对比视图模型 - 处理图片对比逻辑
//

import SwiftUI
import UIKit
import Combine

@MainActor
class ComparisonViewModel: ObservableObject {
    let leftImage: UIImage
    let rightImage: UIImage

    @Published var result: ComparisonResult?
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let imageComparator = ImageComparator()

    init(leftImage: UIImage, rightImage: UIImage) {
        self.leftImage = leftImage
        self.rightImage = rightImage
    }

    func performComparison() async {
        isProcessing = true
        errorMessage = nil
        result = nil

        defer {
            isProcessing = false
        }

        do {
            let comparisonResult = try await imageComparator.compare(
                leftImage,
                with: rightImage
            )
            result = comparisonResult
        } catch {
            errorMessage = error.localizedDescription
            print("对比失败: \(error)")
        }
    }
}
