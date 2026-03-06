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
                    HStack(spacing: 12) {
                        Button {
                            swapLayers()
                        } label: {
                            Label("交换图层", systemImage: "arrow.up.arrow.down")
                        }
                        .disabled(layers.count < 2)

                        Button {
                            dismiss()
                        } label: {
                            Label("返回", systemImage: "xmark")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            swapLayers()
                        } label: {
                            Label("交换图层位置", systemImage: "arrow.up.arrow.down")
                        }
                        .disabled(layers.count < 2)

                        Divider()

                        Button {
                            resetAllLayers()
                        } label: {
                            Label("重置所有图层", systemImage: "arrow.counterclockwise")
                        }

                        Divider()

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

    private func swapLayers() {
        guard layers.count >= 2 else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            // 保存图层属性
            let layer0 = layers[0]
            let layer1 = layers[1]

            // 交换图层（保持各自的属性）
            layers[0] = Layer(
                name: layer1.name,
                image: layer1.image,
                position: layer1.position,
                scale: layer1.scale,
                opacity: layer1.opacity,
                isVisible: layer1.isVisible
            )

            layers[1] = Layer(
                name: layer0.name,
                image: layer0.image,
                position: layer0.position,
                scale: layer0.scale,
                opacity: layer0.opacity,
                isVisible: layer0.isVisible
            )

            // 保持当前选中状态
            if selectedLayerId == layer0.id {
                selectedLayerId = layers[0].id
            } else if selectedLayerId == layer1.id {
                selectedLayerId = layers[1].id
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
