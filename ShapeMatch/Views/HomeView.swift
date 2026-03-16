//
//  HomeView.swift
//  ShapeMatch
//
//  主页面 - 双图选择和对比入口
//

import SwiftUI
import PhotosUI
import AVFoundation

struct HomeView: View {
    @State private var leftImage: UIImage?
    @State private var rightImage: UIImage?
    @State private var showHistory = false
    @State private var isComparing = false
    @State private var shouldShowComparison = false

    var canCompare: Bool {
        leftImage != nil && rightImage != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 标题区域
                    headerSection

                    // 图片选择区域
                    imageSelectionSection
                        .padding(.top, 24)

                    // 操作区域
                    actionSection
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ShapeMatch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16))
                    }
                }
            }
            .navigationDestination(isPresented: $showHistory) {
                ProjectHistoryView()
            }
            .navigationDestination(isPresented: $shouldShowComparison) {
                comparisonDestination
            }
        }
    }

    // MARK: - 子视图

    private var headerSection: some View {
        VStack(spacing: 6) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(.blue)
                .padding(.top, 20)

            Text("选择两张图片，找出差异")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    private var imageSelectionSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ImageCard(
                    image: $leftImage,
                    label: "左图",
                    overlayImage: nil
                )
                .frame(maxWidth: .infinity)

                // 中间箭头 + 互换按钮
                VStack(spacing: 8) {
                    if leftImage != nil && rightImage != nil {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                let temp = leftImage
                                leftImage = rightImage
                                rightImage = temp
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .blue.opacity(0.35), radius: 6, x: 0, y: 3)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(.systemGray4))
                    }
                }
                .frame(width: 34)

                ImageCard(
                    image: $rightImage,
                    label: "右图",
                    overlayImage: leftImage
                )
                .frame(maxWidth: .infinity)
            }

            // 示例图片按钮
            Button {
                loadSampleImages()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "photo.stack")
                        .font(.caption)
                    Text("使用示例图片")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
            }
            .buttonStyle(.borderless)
        }
    }

    private var actionSection: some View {
        VStack(spacing: 14) {
            // 主对比按钮
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                isComparing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isComparing = false
                    shouldShowComparison = true
                }
            } label: {
                ZStack {
                    if isComparing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.85)
                            Text("对比中...")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    } else {
                        Label("开始对比", systemImage: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(!canCompare || isComparing)
            .animation(.easeInOut(duration: 0.2), value: isComparing)
        }
    }

    // MARK: - 辅助

    @ViewBuilder
    private var comparisonDestination: some View {
        if let left = leftImage, let right = rightImage {
            ComparisonView(leftImage: left, rightImage: right)
        }
    }

    private func loadSampleImages() {
        if let img1 = UIImage(named: "pindou1"), let img2 = UIImage(named: "pindou2") {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                leftImage = img1
                rightImage = img2
            }
        }
    }
}

// MARK: - 图片卡片

private struct ImageCard: View {
    @Binding var image: UIImage?
    let label: String
    let overlayImage: UIImage?

    @State private var pickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingSourcePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingCameraAlert = false
    @State private var justSelected = false   // 触发选中动效

    var body: some View {
        VStack(spacing: 10) {
            // 图片预览区
            previewArea
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            image != nil ? Color.blue.opacity(0.5) : Color(.systemGray4),
                            lineWidth: image != nil ? 1.5 : 1
                        )
                )
                .shadow(
                    color: image != nil ? .blue.opacity(0.08) : .clear,
                    radius: 8, x: 0, y: 2
                )
                .overlay(alignment: .topTrailing) {
                    // 已选中的勾
                    if image != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white, .blue)
                            .font(.system(size: 20))
                            .padding(8)
                            .scaleEffect(justSelected ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: justSelected)
                    }
                }
                // 点击整个卡片弹出选择菜单
                .onTapGesture {
                    showingSourcePicker = true
                }
                .confirmationDialog(label, isPresented: $showingSourcePicker, titleVisibility: .visible) {
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Label("从相册选择", systemImage: "photo.on.rectangle")
                    }
                    Button {
                        checkCameraPermission()
                    } label: {
                        Label("拍照", systemImage: "camera")
                    }
                    if image != nil {
                        Button("清除图片", role: .destructive) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                image = nil
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
                .photosPicker(isPresented: $showingPhotoPicker, selection: $pickerItem, matching: .images)

            // 标签
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(image != nil ? .blue : .secondary)
        }
        .onChange(of: pickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        image = uiImage
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    // 短暂的勾号放大动效
                    justSelected = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        justSelected = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            SingleCameraCaptureView(
                overlayImage: overlayImage,
                capturedImage: $image,
                isPresented: $showingCamera
            )
        }
        .alert("无法访问相机", isPresented: $showingCameraAlert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在「设置」中开启相机权限")
        }
    }

    @ViewBuilder
    private var previewArea: some View {
        if let img = image {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .clipped()
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
        } else {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(.systemGray3))

                Text("点击选择")
                    .font(.subheadline)
                    .foregroundStyle(Color(.systemGray3))
            }
        }
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { showingCamera = true }
                    else { showingCameraAlert = true }
                }
            }
        default:
            showingCameraAlert = true
        }
    }
}

#Preview {
    HomeView()
}
