//
//  ComparisonView.swift
//  ShapeMatch
//
//  对比结果展示页面 - 图层叠加模式
//

import SwiftUI

struct ComparisonView: View {
    let leftImage: UIImage
    let rightImage: UIImage
    @StateObject private var viewModel: ComparisonViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var layers: [Layer] = []
    @State private var selectedLayerId: UUID?
    @State private var showLayerPanel = true

    init(leftImage: UIImage, rightImage: UIImage) {
        self.leftImage = leftImage
        self.rightImage = rightImage
        self._viewModel = StateObject(wrappedValue: ComparisonViewModel(
            leftImage: leftImage,
            rightImage: rightImage
        ))
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // 主画布区域
                GeometryReader { geometry in
                    ScrollView([.horizontal, .vertical]) {
                        ZStack {
                            // 棋盘格背景（表示透明）
                            CheckerboardPattern()

                            // 图层叠加
                            ForEach(Array(layers.enumerated()), id: \.element.id) { index, layer in
                                if layer.isVisible {
                                    DraggableImageView(
                                        image: layer.image,
                                        position: binding(for: layer.id, keyPath: \.position),
                                        scale: binding(for: layer.id, keyPath: \.scale),
                                        opacity: binding(for: layer.id, keyPath: \.opacity),
                                        isSelected: selectedLayerId == layer.id,
                                        onTap: {
                                            selectedLayerId = layer.id
                                        }
                                    )
                                    .frame(
                                        width: geometry.size.width,
                                        height: geometry.size.height
                                    )
                                }
                            }
                        }
                        .frame(
                            width: geometry.size.width * 1.5,
                            height: geometry.size.height * 1.5
                        )
                        .onTapGesture {
                            // 点击空白处取消选择
                            selectedLayerId = nil
                        }
                    }
                }

                // 图层面板
                VStack {
                    Spacer()
                    LayerControlPanel(
                        layers: $layers,
                        selectedLayerId: $selectedLayerId,
                        showPanel: $showLayerPanel
                    )
                }
            }
            .navigationTitle("图层对比")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("返回", systemImage: "xmark")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            resetAllLayers()
                        } label: {
                            Label("重置所有图层", systemImage: "arrow.counterclockwise")
                        }

                        Button {
                            // TODO: 导出功能
                        } label: {
                            Label("导出图片", systemImage: "square.and.arrow.up")
                        }
                        .disabled(true)

                        Button {
                            // TODO: 分享功能
                        } label: {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                        .disabled(true)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                setupLayers()
            }
        }
    }

    // MARK: - 辅助方法
    private func setupLayers() {
        layers = [
            Layer(
                name: "底层（原图）",
                image: leftImage,
                position: .zero,
                scale: 1.0,
                opacity: 1.0,
                isVisible: true
            ),
            Layer(
                name: "顶层（对比图）",
                image: rightImage,
                position: .zero,
                scale: 1.0,
                opacity: 0.5,
                isVisible: true
            )
        ]
        selectedLayerId = layers.first?.id
    }

    private func resetAllLayers() {
        withAnimation {
            layers = layers.map { layer in
                Layer(
                    name: layer.name,
                    image: layer.image,
                    position: .zero,
                    scale: 1.0,
                    opacity: layer.name.contains("顶层") ? 0.5 : 1.0,
                    isVisible: true
                )
            }
        }
    }

    // 为特定图层创建绑定
    private func binding(for id: UUID, keyPath: WritableKeyPath<Layer, CGSize>) -> Binding<CGSize> {
        Binding(
            get: {
                guard let index = layers.firstIndex(where: { $0.id == id }) else {
                    return .zero
                }
                return layers[index][keyPath: keyPath]
            },
            set: { newValue in
                guard let index = layers.firstIndex(where: { $0.id == id }) else {
                    return
                }
                layers[index][keyPath: keyPath] = newValue
            }
        )
    }

    private func binding(for id: UUID, keyPath: WritableKeyPath<Layer, CGFloat>) -> Binding<CGFloat> {
        Binding(
            get: {
                guard let index = layers.firstIndex(where: { $0.id == id }) else {
                    return 1.0
                }
                return layers[index][keyPath: keyPath]
            },
            set: { newValue in
                guard let index = layers.firstIndex(where: { $0.id == id }) else {
                    return
                }
                layers[index][keyPath: keyPath] = newValue
            }
        )
    }

    private func binding(for id: UUID, keyPath: WritableKeyPath<Layer, Double>) -> Binding<Double> {
        Binding(
            get: {
                guard let index = layers.firstIndex(where: { $0.id == id }) else {
                    return 1.0
                }
                return layers[index][keyPath: keyPath]
            },
            set: { newValue in
                guard let index = layers.firstIndex(where: { $0.id == id }) else {
                    return
                }
                layers[index][keyPath: keyPath] = newValue
            }
        )
    }
}

// MARK: - 棋盘格背景
struct CheckerboardPattern: View {
    let tileSize: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 浅色背景
                Color(.systemGray5)

                // 深色方块
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height

                    for row in stride(from: 0, to: height, by: tileSize * 2) {
                        for col in stride(from: 0, to: width, by: tileSize * 2) {
                            // 第一个方块
                            path.addRect(CGRect(
                                x: col,
                                y: row,
                                width: tileSize,
                                height: tileSize
                            ))

                            // 对角线方块
                            path.addRect(CGRect(
                                x: col + tileSize,
                                y: row + tileSize,
                                width: tileSize,
                                height: tileSize
                            ))
                        }
                    }
                }
                .fill(Color(.systemGray6))
            }
        }
    }
}

#Preview {
    ComparisonView(
        leftImage: UIImage(systemName: "photo.fill")!,
        rightImage: UIImage(systemName: "photo")!
    )
}
