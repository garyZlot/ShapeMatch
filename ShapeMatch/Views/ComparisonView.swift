//
//  ComparisonView.swift
//  ShapeMatch
//
//  对比结果展示页面 - 图层叠加模式
//

import SwiftUI
import UIKit

struct ComparisonView: View {
    let leftImage: UIImage
    let rightImage: UIImage
    let projectId: UUID?  // 可选的项目 ID（从历史记录加载时使用）
    let projectName: String?  // 可选的项目名称

    @StateObject private var viewModel: ComparisonViewModel

    @State private var layers: [Layer] = []
    @State private var selectedLayerId: UUID?
    @State private var showLayerPanel = true
    @State private var showFineTunePanel = false
    @State private var fineTunePanelPosition = CGPoint(x: 0, y: 0)
    @State private var allLayersLockedScale: CGFloat = 1.0 // 所有图层锁定时的整体缩放
    @State private var lastAllLayersLockedScale: CGFloat = 1.0 // 记录上次的缩放值
    @State private var autoSaveWorkItem: DispatchWorkItem?
    @State private var snapshotCount = 0
    @State private var currentProjectId: UUID?  // 当前项目的 ID

    init(leftImage: UIImage, rightImage: UIImage) {
        self.leftImage = leftImage
        self.rightImage = rightImage
        self.projectId = nil
        self.projectName = nil
        self._viewModel = StateObject(wrappedValue: ComparisonViewModel(
            leftImage: leftImage,
            rightImage: rightImage
        ))
    }

    // 用于从历史记录加载的初始化方法
    init(leftImage: UIImage, rightImage: UIImage, projectId: UUID, projectName: String) {
        self.leftImage = leftImage
        self.rightImage = rightImage
        self.projectId = projectId
        self.projectName = projectName
        self._viewModel = StateObject(wrappedValue: ComparisonViewModel(
            leftImage: leftImage,
            rightImage: rightImage
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 主画布区域
            GeometryReader { geometry in
                overlayModeView(geometry: geometry)
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation {
                        if showFineTunePanel {
                            showFineTunePanel = false
                        } else if selectedLayerId != nil {
                            showFineTunePanel = true
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16))
                }
                .tint(showFineTunePanel ? .blue : .secondary)
                .disabled(selectedLayerId == nil)
            }
        }
        .onAppear {
            loadSavedProject()
        }
        .onDisappear {
            saveProject()
        }
        .onChange(of: layers) { oldValue, newValue in
            scheduleAutoSave()
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

    // MARK: - 项目存储

    /// 加载保存的项目
    private func loadSavedProject() {
        // 如果有指定的项目 ID，从历史记录加载
        if let projectId = projectId {
            loadProject(id: projectId)
        } else {
            // 否则使用默认配置
            setupLayers()
        }
    }

    /// 从项目 ID 加载
    private func loadProject(id: UUID) {
        ProjectStorage.shared.loadProject(id: id) { result in
            switch result {
            case .success(let projectData):
                // 恢复图层
                let restoredLayers = ProjectStorage.shared.restoreLayers(from: projectData)
                layers = restoredLayers
                selectedLayerId = layers.first?.id

                // 设置当前项目 ID（这样自动保存会更新这个项目，而不是创建新的）
                currentProjectId = id

                print("✅ 已恢复项目: \(projectData.name) (\(projectData.layers.count) 个图层)")

            case .failure(let error):
                print("❌ 加载项目失败: \(error.localizedDescription)")
                // 加载失败时使用默认配置
                setupLayers()
            }
        }
    }

    /// 保存项目
    private func saveProject() {
        // 如果还没有当前项目 ID，创建一个
        if currentProjectId == nil {
            currentProjectId = UUID()
        }

        let id = currentProjectId!
        let name = projectName ?? "对比项目 \(DateFormatter.shortDate.string(from: Date()))"

        ProjectStorage.shared.saveProject(id: id, name: name, layers: layers) { result in
            switch result {
            case .success:
                print("✅ 项目已自动保存: \(name)")
            case .failure(let error):
                print("❌ 保存项目失败: \(error.localizedDescription)")
            }
        }
    }

    /// 调度自动保存（延迟2秒）
    private func scheduleAutoSave() {
        // 取消之前的保存任务
        autoSaveWorkItem?.cancel()

        // 创建新的保存任务
        let workItem = DispatchWorkItem {
            saveProject()
        }

        autoSaveWorkItem = workItem

        // 延迟2秒执行
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
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
