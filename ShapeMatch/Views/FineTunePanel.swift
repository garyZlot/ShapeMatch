//
//  FineTunePanel.swift
//  ShapeMatch
//
//  浮动微调面板 - 精确调整位置、缩放、旋转
//

import SwiftUI

struct FineTunePanel: View {
    @Binding var position: CGSize
    @Binding var scale: CGFloat
    @Binding var rotation: Double
    @Binding var panelPosition: CGPoint
    let onReset: () -> Void
    let onClose: () -> Void

    // 步长设置
    private let positionStep: CGFloat = 1.0
    private let scaleStep: CGFloat = 0.01
    private let rotationStep: Double = 1.0

    // ✅ @GestureState：仅在手势期间存储偏移，手势结束自动归零，不触发父视图重渲染
    @GestureState private var dragOffset: CGSize = .zero

    // 整个面板的拖动手势
    private var panelDragGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .global)
            .updating($dragOffset) { value, state, _ in
                // ✅ 只更新 @GestureState，不碰 @Binding，父视图不会重渲染
                state = value.translation
            }
            .onEnded { value in
                // ✅ 拖动结束才写回 @Binding，一次性提交
                panelPosition = CGPoint(
                    x: panelPosition.x + value.translation.width,
                    y: panelPosition.y + value.translation.height
                )
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Button {
                    onReset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)

                Text("精细调整")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(height: 36)
            .background(Color(.systemGray6))

            Divider()

            VStack(spacing: 12) {
                // 位置调整
                VStack(spacing: 6) {
                    Text("位置")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // 方向键十字形布局（键盘布局）
                    VStack(spacing: 4) {
                        // 上箭头
                        Button { adjustPosition(x: 0, y: -positionStep) } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .frame(width: 40, height: 32)

                        // 中间行：左、下、右
                        HStack(spacing: 4) {
                            Button { adjustPosition(x: -positionStep, y: 0) } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .frame(width: 40, height: 32)

                            Button { adjustPosition(x: 0, y: positionStep) } label: {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .frame(width: 40, height: 32)

                            Button { adjustPosition(x: positionStep, y: 0) } label: {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .frame(width: 40, height: 32)
                        }

                        // 坐标显示
                        Text("(\(Int(position.width)), \(Int(position.height)))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // 缩放调整
                VStack(spacing: 6) {
                    Text("缩放")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button { adjustScale(-scaleStep) } label: {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Text(String(format: "%.0f%%", scale * 100))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 40)

                        Button { adjustScale(scaleStep) } label: {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                // 旋转调整
                VStack(spacing: 6) {
                    Text("旋转")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button { adjustRotation(-rotationStep) } label: {
                            Image(systemName: "rotate.left")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Text(String(format: "%.0f°", rotation))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 40)

                        Button { adjustRotation(rotationStep) } label: {
                            Image(systemName: "rotate.right")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .padding(12)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .frame(width: 160)
        // ✅ 拖动时用本地 dragOffset 实时移动，不回写 @Binding，彻底消除抖动
        .position(
            CGPoint(
                x: panelPosition.x + dragOffset.width,
                y: panelPosition.y + dragOffset.height
            )
        )
        // ✅ 整个面板都可拖动，按钮点击因 minimumDistance: 4 不会误触发拖动
        .gesture(panelDragGesture)
    }

    // MARK: - 调整方法
    private func adjustPosition(x: CGFloat, y: CGFloat) {
        withAnimation(.linear(duration: 0.05)) {
            position = CGSize(
                width: position.width + x,
                height: position.height + y
            )
        }
    }

    private func adjustScale(_ delta: CGFloat) {
        withAnimation(.linear(duration: 0.05)) {
            scale = max(0.1, min(scale + delta, 5.0))
        }
    }

    private func adjustRotation(_ delta: Double) {
        withAnimation(.linear(duration: 0.05)) {
            rotation = rotation + delta
        }
    }
}

#Preview {
    FineTunePanel(
        position: .constant(.zero),
        scale: .constant(1.0),
        rotation: .constant(0.0),
        panelPosition: .constant(CGPoint(x: 200, y: 200)),
        onReset: {},
        onClose: {}
    )
}
