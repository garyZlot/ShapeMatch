//
//  ImagePickerView.swift
//  ShapeMatch
//
//  图片选择视图 - 支持相册和拍照
//

import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Binding var selectedImage: UIImage?
    let sourceType: SourceType
    let title: String

    enum SourceType {
        case left
        case right
    }

    @State private var pickerItem: PhotosPickerItem?
    @State private var showingImagePicker = false

    var body: some View {
        VStack(spacing: 12) {
            // 图片预览区
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text(sourceType == .left ? "选择左图" : "选择右图")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("从相册或拍照")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(height: 200)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )

            // 选择按钮
            HStack(spacing: 12) {
                // 相册按钮
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("相册", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .onChange(of: pickerItem) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }

                // 拍照按钮（需要真机）
                Button {
                    showingImagePicker = true
                } label: {
                    Label("拍照", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(true) // 暂时禁用，后续可添加相机支持
            }

            // 清除按钮
            if selectedImage != nil {
                Button {
                    selectedImage = nil
                } label: {
                    Label("清除", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

#Preview {
    VStack {
        ImagePickerView(
            selectedImage: .constant(nil),
            sourceType: .left,
            title: "左图"
        )
        ImagePickerView(
            selectedImage: .constant(UIImage(systemName: "photo")),
            sourceType: .right,
            title: "右图"
        )
    }
    .padding()
}
