//
//  ComparisonView.swift
//  ShapeMatch
//
//  对比结果展示页面 - 图层叠加模式
//

import SwiftUI
import UIKit

// 对比模式枚举
enum ComparisonMode: String, CaseIterable {
    case overlay = "叠加"
    case sideBySide = "分屏"

    var icon: String {
        switch self {
        case .overlay: return "square.stack.3d.up"
        case .sideBySide: return "square.split.2x1"
        }
    }
}

struct ComparisonView: View {
    let leftImage: UIImage
    let rightImage: UIImage
    @StateObject private var viewModel: ComparisonViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var layers: [Layer] = []
    @State private var selectedLayerId: UUID?
    @State private var showLayerPanel = true
    @State private var showFineTunePanel = false
    @State private var fineTunePanelPosition = CGPoint(x: 0, y: 0)
    @State private var comparisonMode: ComparisonMode = .overlay
    @State private var splitPosition: CGFloat = 0.5 // 分屏分割位置 (0.0 - 1.0)
    @State private var allLayersLockedScale: CGFloat = 1.0 // 所有图层锁定时的整体缩放
    @State private var lastAllLayersLockedScale: CGFloat = 1.0 // 记录上次的缩放值

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
                    Group {
                        if comparisonMode == .overlay {
                            // 叠加模式
                            overlayModeView(geometry: geometry)
                        } else {
                            // 分屏模式
                            sideBySideModeView(geometry: geometry)
                        }
                    }
                }

                // 图层面板
                VStack {
                    Spacer()
                    LayerControlPanel(
                        layers: $layers,
                        selectedLayerId: $selectedLayerId,
                        showPanel: $showLayerPanel,
                        onSwapLayers: {
                            swapLayers()
                        },
                        onResetAll: {
                            resetAllLayers()
                        }
                    )
                }
            }
            .navigationTitle("图层对比")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        // 对比模式切换
                        Picker("对比模式", selection: $comparisonMode) {
                            ForEach(ComparisonMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        // 微调面板切换按钮
                        Button {
                            withAnimation {
                                if showFineTunePanel {
                                    showFineTunePanel = false
                                } else if selectedLayerId != nil {
                                    showFineTunePanel = true
                                }
                            }
                        } label: {
                            Label("微调", systemImage: "slider.horizontal.3")
                        }
                        .tint(showFineTunePanel ? .blue : .secondary)
                        .disabled(selectedLayerId == nil || comparisonMode == .sideBySide)

                        Button {
                            dismiss()
                        } label: {
                            Label("返回", systemImage: "xmark")
                        }
                    }
                }
            }
            .onAppear {
                setupLayers()
            }
        }
        .overlay(alignment: .topLeading) {
            // 浮动微调面板 - 在根视图层级
            if showFineTunePanel, let selectedId = selectedLayerId,
               let index = layers.firstIndex(where: { $0.id == selectedId }) {
                FineTunePanel(
                    layerName: layers[index].name,
                    position: binding(for: selectedId, keyPath: \.position),
                    scale: binding(for: selectedId, keyPath: \.scale),
                    rotation: binding(for: selectedId, keyPath: \.rotation),
                    panelPosition: $fineTunePanelPosition,
                    onReset: {
                        layers[index].position = .zero
                        layers[index].scale = 1.0
                        layers[index].rotation = 0.0
                    },
                    onClose: {
                        withAnimation {
                            showFineTunePanel = false
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }
        }
    }

    // 获取屏幕尺寸的辅助方法
    private var screenWidth: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.width
        #else
        return 400  // macOS 默认值
        #endif
    }

    // MARK: - 辅助方法

    // 检查是否所有可见图层都已锁定
    private var areAllLayersLocked: Bool {
        layers.filter { $0.isVisible }.allSatisfy { $0.isLocked }
    }

    private func setupLayers() {
        layers = [
            Layer(
                name: "底层（原图）",
                image: leftImage,
                position: .zero,
                scale: 1.0,
                opacity: 1.0,
                isVisible: true,
                isLocked: false,
                rotation: 0.0
            ),
            Layer(
                name: "顶层（对比图）",
                image: rightImage,
                position: .zero,
                scale: 1.0,
                opacity: 0.5,
                isVisible: true,
                isLocked: false,
                rotation: 0.0
            )
        ]
        selectedLayerId = layers.first?.id

        // 设置微调面板的初始位置（右侧中部）
        fineTunePanelPosition = CGPoint(x: screenWidth - 100, y: 200)
    }

    private func resetAllLayers() {
        withAnimation {
            // 重置整体缩放
            allLayersLockedScale = 1.0
            lastAllLayersLockedScale = 1.0

            layers = layers.map { layer in
                Layer(
                    name: layer.name,
                    image: layer.image,
                    position: .zero,
                    scale: 1.0,
                    opacity: layer.name.contains("顶层") ? 0.5 : 1.0,
                    isVisible: true,
                    isLocked: false,
                    rotation: 0.0
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
                isVisible: layer1.isVisible,
                isLocked: layer1.isLocked,
                rotation: layer1.rotation
            )

            layers[1] = Layer(
                name: layer0.name,
                image: layer0.image,
                position: layer0.position,
                scale: layer0.scale,
                opacity: layer0.opacity,
                isVisible: layer0.isVisible,
                isLocked: layer0.isLocked,
                rotation: layer0.rotation
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

    // MARK: - 对比模式视图
    private func overlayModeView(geometry: GeometryProxy) -> some View {
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
                            rotation: binding(for: layer.id, keyPath: \.rotation),
                            isSelected: selectedLayerId == layer.id,
                            isLocked: layer.isLocked,
                            onTap: {
                                selectedLayerId = layer.id
                            }
                        )
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .scaleEffect(areAllLayersLocked ? allLayersLockedScale : 1.0)
                    }
                }

                // 所有图层锁定时的提示
                if areAllLayersLocked && allLayersLockedScale != 1.0 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(String(format: "整体缩放: %.0f%%", allLayersLockedScale * 100))
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .shadow(radius: 2)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .frame(
                width: geometry.size.width * 1.5,
                height: geometry.size.height * 1.5
            )
            .onTapGesture {
                selectedLayerId = nil
                withAnimation {
                    showFineTunePanel = false
                }
            }
            // 当所有图层都锁定时，允许整体缩放
            .gesture(
                areAllLayersLocked ? MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastAllLayersLockedScale
                        lastAllLayersLockedScale = value
                        allLayersLockedScale = max(0.5, min(allLayersLockedScale * delta, 3.0))
                    }
                    .onEnded { _ in
                        lastAllLayersLockedScale = 1.0
                    }
                : nil
            )
        }
    }

    private func sideBySideModeView(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .leading) {
            // 左侧：底层图片
            let leftLayer = layers.first
            Image(uiImage: leftLayer?.image ?? leftImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            // 右侧：顶层图片
            let rightLayer = layers.count > 1 ? layers[1] : nil
            GeometryReader { geo in
                Image(uiImage: rightLayer?.image ?? rightImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .frame(width: geo.size.width)
                    .offset(x: geo.size.width * splitPosition)
            }

            // 分割线
            Divider()
                .frame(height: 60)
                .background(Color(.systemBackground))
                .overlay(
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        )
                )
                .offset(x: geometry.size.width * splitPosition - 30)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newPosition = value.location.x / geometry.size.width
                            splitPosition = max(0.1, min(newPosition, 0.9))
                        }
                )

            // 左右标签
            VStack {
                HStack {
                    Text(layers.first?.name ?? "底层")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemBackground))
                        .clipShape(Capsule())
                        .shadow(radius: 2)

                    Spacer()

                    Text(layers.count > 1 ? layers[1].name : "顶层")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemBackground))
                        .clipShape(Capsule())
                        .shadow(radius: 2)
                }
                .padding()
                Spacer()
            }
        }
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
