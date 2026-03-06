//
//  ComparisonView.swift
//  ShapeMatch
//
//  对比结果展示页面 - 显示两张图片和差异标注
//

import SwiftUI

struct ComparisonView: View {
    let leftImage: UIImage
    let rightImage: UIImage
    @StateObject private var viewModel: ComparisonViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DisplayTab = .sideBySide

    enum DisplayTab: String, CaseIterable {
        case sideBySide = "并排"
        case overlay = "叠加"
        case difference = "差异"

        var icon: String {
            switch self {
            case .sideBySide: return "square.split.2x1"
            case .overlay: return "layers"
            case .difference: return "circle.circle"
            }
        }
    }

    init(leftImage: UIImage, rightImage: UIImage) {
        self.leftImage = leftImage
        self.rightImage = rightImage
        self._viewModel = StateObject(wrappedValue: ComparisonViewModel(
            leftImage: leftImage,
            rightImage: rightImage
        ))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 显示模式选择
                Picker("显示模式", selection: $selectedTab) {
                    ForEach(DisplayTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // 图片显示区域
                ScrollView([.horizontal, .vertical]) {
                    Group {
                        switch selectedTab {
                        case .sideBySide:
                            SideBySideView(
                                leftImage: leftImage,
                                rightImage: rightImage,
                                differences: viewModel.result?.differences ?? []
                            )
                        case .overlay:
                            OverlayView(
                                baseImage: leftImage,
                                overlayImage: rightImage
                            )
                        case .difference:
                            DifferenceView(
                                leftImage: leftImage,
                                rightImage: rightImage,
                                differences: viewModel.result?.differences ?? []
                            )
                        }
                    }
                }

                Divider()

                // 底部信息栏
                VStack(spacing: 8) {
                    if let result = viewModel.result {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("相似度")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(result.similarity * 100))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(result.similarity > 0.8 ? .green : .orange)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("差异点")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(result.differences.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else if viewModel.isProcessing {
                        HStack {
                            ProgressView()
                            Text("正在分析...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("对比结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("返回", systemImage: "xmark")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: 分享功能
                    } label: {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    .disabled(true)
                }
            }
        }
        .task {
            await viewModel.performComparison()
        }
    }
}

// MARK: - 并排显示视图
struct SideBySideView: View {
    let leftImage: UIImage
    let rightImage: UIImage
    let differences: [DifferencePoint]

    var body: some View {
        HStack(spacing: 0) {
            // 左图
            VStack {
                Text("原图")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(uiImage: leftImage)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        // 差异标注
                        DifferenceOverlay(differences: differences)
                    }
            }
            .frame(maxWidth: .infinity)

            Divider()

            // 右图
            VStack {
                Text("对比图")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(uiImage: rightImage)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        DifferenceOverlay(differences: differences)
                    }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - 叠加显示视图
struct OverlayView: View {
    let baseImage: UIImage
    let overlayImage: UIImage
    @State private var opacity: CGFloat = 0.5

    var body: some View {
        VStack {
            ZStack {
                Image(uiImage: baseImage)
                    .resizable()
                    .scaledToFit()

                Image(uiImage: overlayImage)
                    .resizable()
                    .scaledToFit()
                    .opacity(opacity)
            }
            .cornerRadius(10)

            Slider(value: $opacity, in: 0...1) {
                Text("透明度")
            }
            .padding()
        }
        .padding()
    }
}

// MARK: - 差异显示视图
struct DifferenceView: View {
    let leftImage: UIImage
    let rightImage: UIImage
    let differences: [DifferencePoint]

    var body: some View {
        VStack {
            Text("差异检测结果")
                .font(.headline)
                .padding()

            if differences.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    Text("未发现明显差异")
                        .font(.title3)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(differences.prefix(10)) { diff in
                        HStack {
                            Circle()
                                .fill(diff.intensity > 0.7 ? .red : .orange)
                                .frame(width: 12, height: 12)

                            VStack(alignment: .leading) {
                                Text("差异点 \(differences.firstIndex(where: { $0.id == diff.id })! + 1)")
                                    .font(.subheadline)
                                Text("强度: \(Int(diff.intensity * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    if differences.count > 10 {
                        Text("还有 \(differences.count - 10) 个差异点...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - 差异标注覆盖层
struct DifferenceOverlay: View {
    let differences: [DifferencePoint]

    var body: some View {
        GeometryReader { geometry in
            ForEach(differences) { diff in
                Circle()
                    .stroke(
                        diff.intensity > 0.7 ? Color.red : Color.orange,
                        lineWidth: 3
                    )
                    .frame(
                        width: diff.size,
                        height: diff.size
                    )
                    .position(
                        x: diff.location.x * geometry.size.width,
                        y: diff.location.y * geometry.size.height
                    )
            }
        }
    }
}

#Preview {
    ComparisonView(
        leftImage: UIImage(systemName: "photo")!,
        rightImage: UIImage(systemName: "photo.fill")!
    )
}
