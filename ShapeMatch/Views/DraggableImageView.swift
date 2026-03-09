//
//  DraggableImageView.swift
//  ShapeMatch
//
//  可拖拽、缩放的图片视图
//

import SwiftUI

struct DraggableImageView: View {
    let image: UIImage
    @Binding var position: CGSize
    @Binding var scale: CGFloat
    @Binding var opacity: Double
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    @State private var lastScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(
                x: position.width + dragOffset.width,
                y: position.height + dragOffset.height
            )
            .overlay(
                // 选中边框
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? (isLocked ? Color.orange : Color.blue) : Color.clear, lineWidth: 2)
            )
            .overlay(
                // 选中时显示的指示器
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                // 锁定图标
                                if isLocked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.orange)
                                        .padding(6)
                                        .background(Circle()
                                            .fill(.ultraThinMaterial)
                                            .shadow(radius: 2))
                                }

                                Spacer()

                                Circle()
                                    .fill(isLocked ? Color.orange : Color.blue)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(systemName: "plus.magnifyingglass")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.white)
                                    )
                            }
                            Spacer()
                        }
                    }
                }
            )
            .gesture(
                // 拖拽手势 - 锁定时禁用
                isLocked ? nil : DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        // 更新最终位置
                        position = CGSize(
                            width: position.width + value.translation.width,
                            height: position.height + value.translation.height
                        )
                        dragOffset = .zero
                    }
            )
            .gesture(
                // 缩放手势 - 锁定时禁用
                isLocked ? nil : MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        scale = max(0.1, min(scale * delta, 5.0))
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                    }
            )
            .onTapGesture(count: 2) {
                onTap()
            }
            .shadow(radius: isSelected ? 10 : 0)
    }
}

#Preview {
    DraggableImageView(
        image: UIImage(systemName: "photo")!,
        position: .constant(.zero),
        scale: .constant(1.0),
        opacity: .constant(1.0),
        isSelected: true,
        isLocked: false,
        onTap: {}
    )
    .frame(width: 300, height: 300)
}
