//
//  ImagePickerView.swift
//  ShapeMatch
//
//  图片选择视图 - 支持相册和拍照
//

import SwiftUI
import PhotosUI
import AVFoundation

struct ImagePickerView: View {
    @Binding var selectedImage: UIImage?
    let sourceType: SourceType
    let title: String
    let overlayImage: UIImage?

    enum SourceType {
        case left
        case right
    }

    @State private var pickerItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingCameraCapture = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

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

                // 拍照按钮
                Button {
                    checkCameraPermission()
                } label: {
                    Label("拍照", systemImage: "camera")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
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
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingCameraCapture) {
            // 单次拍照，如果有 overlayImage 则显示为半透明遮罩
            SingleCameraCaptureView(
                overlayImage: overlayImage,
                capturedImage: $selectedImage,
                isPresented: $showingCameraCapture
            )
        }
    }

    // MARK: - 辅助方法
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCameraCapture = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCameraCapture = true
                    } else {
                        alertMessage = "需要相机权限才能使用拍照功能"
                        showingAlert = true
                    }
                }
            }
        case .denied, .restricted:
            alertMessage = "相机权限已被拒绝，请在设置中开启"
            showingAlert = true
        @unknown default:
            alertMessage = "无法访问相机"
            showingAlert = true
        }
    }
}

#Preview {
    VStack {
        ImagePickerView(
            selectedImage: .constant(nil),
            sourceType: .left,
            title: "左图",
            overlayImage: nil
        )
        ImagePickerView(
            selectedImage: .constant(UIImage(systemName: "photo")),
            sourceType: .right,
            title: "右图",
            overlayImage: nil
        )
    }
    .padding()
}
