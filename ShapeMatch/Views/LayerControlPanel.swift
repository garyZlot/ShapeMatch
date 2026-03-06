//
//  LayerControlPanel.swift
//  ShapeMatch
//
//  图层控制面板
//

import SwiftUI

struct LayerControlPanel: View {
    @Binding var layers: [Layer]
    @Binding var selectedLayerId: UUID?
    @Binding var showPanel: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 面板头部
            HStack {
                Text("图层")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    withAnimation {
                        showPanel = false
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white)
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
                            onOpacityChange: { newOpacity in
                                layers[index].opacity = newOpacity
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
        .frame(height: showPanel ? 250 : 0)
        .frame(maxWidth: .infinity)
        .overlay(
            // 最小化时的展开按钮
            Group {
                if !showPanel {
                    Button {
                        withAnimation {
                            showPanel = true
                        }
                    } label: {
                        HStack {
                            Text("图层")
                                .font(.caption)
                                .foregroundColor(.white)
                            Image(systemName: "chevron.up")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                    .padding(.bottom, 8)
                }
            },
            alignment: .top
        )
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

    @State private var isEditingOpacity = false

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

                if isEditingOpacity {
                    // 透明度滑块
                    HStack(spacing: 8) {
                        Image(systemName: "opacity")
                            .font(.caption)
                        Slider(value: Binding(
                            get: { layer.opacity },
                            set: { onOpacityChange($0) }
                        ), in: 0...1)
                            .frame(width: 120)
                        Text("\(Int(layer.opacity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 35)
                    }
                } else {
                    // 图层信息
                    HStack(spacing: 6) {
                        Image(systemName: "scale.3d")
                            .font(.caption2)
                        Text("x\(String(format: "%.1f", layer.scale))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer().frame(width: 8)

                        Image(systemName: "arrow.up.forward")
                            .font(.caption2)
                        Text("\(Int(layer.position.width)), \(Int(layer.position.height))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // 可见性切换按钮
            Button {
                onVisibilityToggle()
            } label: {
                Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(layer.isVisible ? .blue : .secondary)
            }
            .buttonStyle(.borderless)

            // 透明度编辑按钮
            Button {
                withAnimation {
                    isEditingOpacity.toggle()
                }
            } label: {
                Image(systemName: isEditingOpacity ? "checkmark" : "slider.horizontal.3")
                    .font(.caption)
                    .foregroundColor(isEditingOpacity ? .blue : .secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
            if isEditingOpacity {
                withAnimation {
                    isEditingOpacity = false
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
            showPanel: .constant(true)
        )
    }
}
