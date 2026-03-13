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
        VStack(spacing: 8) {
            // 图片预览区
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)

                        Text(sourceType == .left ? "左图" : "右图")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("选择图片")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(width: 80, height: 140)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )

            // 选择按钮
            HStack(spacing: 8) {
                // 相册按钮
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("相册", systemImage: "photo.on.rectangle")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.small)
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
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(true) // 暂时禁用，后续可添加相机支持
            }

            // 清除按钮
            if selectedImage != nil {
                Button {
                    selectedImage = nil
                } label: {
                    Label("清除", systemImage: "xmark.circle.fill")
                        .font(.caption)
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
