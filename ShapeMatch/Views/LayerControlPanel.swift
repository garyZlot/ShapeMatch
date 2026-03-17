//
//  LayerControlPanel.swift
//  ShapeMatch
//
//  图层控制面板
//

import SwiftUI
import UIKit

struct LayerControlPanel: View {
    @Binding var layers: [Layer]
    @Binding var selectedLayerId: UUID?
    @Binding var showPanel: Bool
    let onSwapLayers: () -> Void
    let onResetAll: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if showPanel {
                // 展开状态：完整面板
                VStack(spacing: 0) {
                    // 面板头部
                    HStack {
                        Text("图层")
                            .font(.headline)

                        Spacer()

                        // 快捷操作按钮组
                        HStack(spacing: 8) {
                            // 交换图层按钮
                            Button {
                                onSwapLayers()
                            } label: {
                                Label("交换", systemImage: "arrow.up.arrow.down")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .disabled(layers.count < 2)

                            // 重置全部按钮
                            Button {
                                onResetAll()
                            } label: {
                                Label("重置", systemImage: "arrow.counterclockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)

                            // 最小化按钮
                            Button {
                                withAnimation {
                                    showPanel = false
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))

                    Divider()

                    // 图层列表
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(layers.enumerated()), id: \.element.id) { index, layer in
                                LayerRow(
                                    layer: layer,
                                    isSelected: selectedLayerId == layer.id,
                                    onTap: {
                                        selectedLayerId = layer.id
                                    },
                                    onVisibilityToggle: {
                                        layers[index].isVisible.toggle()
                                    },
                                    onOpacityChange: { newValue in
                                        layers[index].opacity = newValue
                                    },
                                    onLockToggle: {
                                        layers[index].isLocked.toggle()
                                    }
                                )

                                if index < layers.count - 1 {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                    }

                    // 底部提示
                    VStack(spacing: 4) {
                        Text("双击图片选择图层")
                            .font(.caption)
                        Text("双指缩放 · 单指拖动")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                // 最小化状态：只显示顶层切换按钮和展开按钮
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Spacer()

                        // 找到顶层图层（通常是第二个图层）
                        if layers.count >= 2 {
                            let topLayerIndex = 1
                            let topLayer = layers[topLayerIndex]

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    layers[topLayerIndex].isVisible.toggle()
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: topLayer.isVisible ? "eye.fill" : "eye.slash.fill")
                                        .font(.caption)
                                    Text("顶层")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(topLayer.isVisible ? Color.blue : Color.gray)
                                .clipShape(Capsule())
                            }
                        }

                        // 展开按钮
                        Button {
                            withAnimation {
                                showPanel = true
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.7))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.bottom, 8)
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity)
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3), value: showPanel)
    }
}

// MARK: - 图层行
struct LayerRow: View {
    let layer: Layer
    let isSelected: Bool
    let onTap: () -> Void
    let onVisibilityToggle: () -> Void
    let onOpacityChange: (Double) -> Void
    let onLockToggle: () -> Void

    @State private var showOpacitySlider = false

    var body: some View {
        HStack(spacing: 12) {
            // 选中指示器
            Rectangle()
                .fill(isSelected ? Color.blue : Color.clear)
                .frame(width: 4)

            // 图层缩略图
            Image(uiImage: layer.image)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .opacity(layer.isVisible ? layer.opacity : 0.3)

            // 图层信息
            VStack(alignment: .leading, spacing: 4) {
                Text(layer.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)

                if showOpacitySlider {
                    // 透明度滑块 - 独占一行
                    HStack(spacing: 8) {
                        Image(systemName: "opacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(
                            value: Binding(
                                get: { layer.opacity },
                                set: { newValue in
                                    onOpacityChange(newValue)
                                }
                            ),
                            in: 0...1
                        )
                        Text("\(Int(layer.opacity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 35)
                    }
                    .transition(.opacity)
                } else {
                    // 图层信息 - 一行显示
                    HStack(spacing: 6) {
                        Image(systemName: "scale.3d")
                            .font(.caption2)
                        Text("x\(String(format: "%.1f", layer.scale))")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer().frame(width: 6)

                        Image(systemName: "arrow.up.forward")
                            .font(.caption2)
                        Text("\(Int(layer.position.width)), \(Int(layer.position.height))")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer().frame(width: 6)

                        // 可点击的透明度值
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showOpacitySlider.toggle()
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "opacity")
                                    .font(.caption2)
                                Text("\(Int(layer.opacity * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 可见性切换按钮
            Button {
                onVisibilityToggle()
            } label: {
                Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(layer.isVisible ? .blue : .secondary)
            }
            .buttonStyle(.borderless)

            // 锁定按钮
            Button {
                onLockToggle()
            } label: {
                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open.fill")
                    .foregroundColor(layer.isLocked ? .orange : .secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
            // 点击其他区域时收起滑块
            if showOpacitySlider {
                withAnimation {
                    showOpacitySlider = false
                }
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        LayerControlPanel(
            layers: .constant([
                Layer(name: "原图", image: UIImage(systemName: "photo.fill")!),
                Layer(name: "对比图", image: UIImage(systemName: "photo")!)
            ]),
            selectedLayerId: .constant(UUID()),
            showPanel: .constant(true),
            onSwapLayers: {},
            onResetAll: {}
        )
    }
}
