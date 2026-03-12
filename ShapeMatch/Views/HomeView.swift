//
//  HomeView.swift
//  ShapeMatch
//
//  主页面 - 双图选择和对比入口
//

import SwiftUI

struct HomeView: View {
    @State private var leftImage: UIImage?
    @State private var rightImage: UIImage?
    @State private var showHistory = false
    @State private var isComparing = false
    @State private var shouldShowComparison = false
    @State private var selectedProjectId: UUID?
    @State private var selectedProjectName: String?
    @State private var shouldAutoNavigate = false

    var canCompare: Bool {
        leftImage != nil && rightImage != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 标题区域
                VStack(spacing: 4) {
                    Image(systemName: "eye.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)

                    Text("图片对比")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("选择两张图片，快速找出差异")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)

                // 图片选择区域 - 横向排列
                HStack(spacing: 12) {
                    ImagePickerView(
                        selectedImage: $leftImage,
                        sourceType: .left,
                        title: "左图"
                    )

                    ImagePickerView(
                        selectedImage: $rightImage,
                        sourceType: .right,
                        title: "右图"
                    )
                }
                .padding(.horizontal, 16)

                // 使用示例图片按钮
                Button {
                    loadSampleImages()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.stack")
                        Text("使用示例图片")
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.borderless)

                // 对比按钮
                Button {
                    isComparing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isComparing = false
                        shouldShowComparison = true
                    }
                } label: {
                    if isComparing {
                        HStack(spacing: 6) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("对比中...")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Label("开始对比", systemImage: "magnifyingglass")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.regular)
                .disabled(!canCompare || isComparing)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

                // 提示信息
                if !canCompare {
                    Text("请选择两张图片后开始对比")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
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
                ProjectHistoryView { projectId in
                    loadProjectAndNavigate(projectId)
                }
            }
            .navigationDestination(isPresented: $shouldShowComparison) {
                comparisonDestination
            }
            .onChange(of: shouldShowComparison) { newValue in
                // 当用户返回时，清除状态
                if !newValue {
                    selectedProjectId = nil
                    selectedProjectName = nil
                    shouldAutoNavigate = false
                }
            }
        }
    }

    // MARK: - 计算属性
    @ViewBuilder
    private var comparisonDestination: some View {
        if let left = leftImage, let right = rightImage {
            if let projectId = selectedProjectId,
               let projectName = selectedProjectName {
                // 从历史记录加载
                ComparisonView(
                    leftImage: left,
                    rightImage: right,
                    projectId: projectId,
                    projectName: projectName
                )
            } else {
                // 新建对比
                ComparisonView(
                    leftImage: left,
                    rightImage: right
                )
            }
        }
    }

    // MARK: - 辅助方法
    private func loadSampleImages() {
        if let img1 = UIImage(named: "pindou1"), let img2 = UIImage(named: "pindou2") {
            leftImage = img1
            rightImage = img2
        }
    }

    private func loadProjectAndNavigate(_ id: UUID) {
        ProjectStorage.shared.loadProject(id: id) { result in
            switch result {
            case .success(let projectData):
                // 恢复图层
                let layers = ProjectStorage.shared.restoreLayers(from: projectData)

                if layers.count >= 2 {
                    // 设置图片
                    leftImage = layers[0].image
                    rightImage = layers[1].image

                    // 设置项目信息，用于标识是历史项目
                    selectedProjectId = id
                    selectedProjectName = projectData.name

                    // 关闭历史列表，进入对比页面
                    showHistory = false
                    shouldShowComparison = true

                    print("✅ 已加载项目: \(projectData.name)")
                }

            case .failure(let error):
                print("❌ 加载项目失败: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    HomeView()
}
