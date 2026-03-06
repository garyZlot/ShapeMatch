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
    let onTap: () -> Void

    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(position)
            .overlay(
                // 选中边框
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .overlay(
                // 选中时显示调整手柄
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(Color.blue)
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
                // 拖拽手势
                DragGesture()
                    .onChanged { value in
                        position = CGSize(
                            width: value.translation.width + position.width,
                            height: value.translation.height + position.height
                        )
                    }
            )
            .gesture(
                // 缩放手势
                MagnificationGesture()
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
        onTap: {}
    )
    .frame(width: 300, height: 300)
}
