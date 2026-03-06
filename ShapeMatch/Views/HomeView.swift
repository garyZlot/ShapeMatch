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
    @State private var showComparison = false
    @State private var isComparing = false

    var canCompare: Bool {
        leftImage != nil && rightImage != nil
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题区域
                    VStack(spacing: 8) {
                        Image(systemName: "eye.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("图片对比")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("选择两张图片，快速找出差异")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // 图片选择区域
                    VStack(spacing: 20) {
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
                    .padding(.horizontal)

                    // 对比按钮
                    Button {
                        isComparing = true
                        // 延迟一点显示结果页面
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isComparing = false
                            showComparison = true
                        }
                    } label: {
                        if isComparing {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("对比中...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("开始对比", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .disabled(!canCompare || isComparing)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)

                    // 提示信息
                    if !canCompare {
                        Text("请选择两张图片后开始对比")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("ShapeMatch")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showComparison) {
            if let left = leftImage, let right = rightImage {
                ComparisonView(
                    leftImage: left,
                    rightImage: right
                )
            }
        }
    }
}

#Preview {
    HomeView()
}
