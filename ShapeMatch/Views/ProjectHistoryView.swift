//
//  ProjectHistoryView.swift
//  ShapeMatch
//
//  项目历史列表视图
//

import SwiftUI

struct ProjectHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var projects: [ProjectMetadata] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showDeleteAlert = false
    @State private var projectToDelete: ProjectMetadata?

    let onLoadProject: (UUID) -> Void

    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载中...")
            } else if projects.isEmpty {
                emptyStateView
            } else {
                projectListView
            }
        }
        .navigationTitle("历史对比")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadProjects()
        }
        .alert("删除项目", isPresented: $showDeleteAlert, presenting: projectToDelete) { project in
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteProject(project)
            }
        } message: { project in
            Text("确定要删除\"\(project.name)\"吗？")
        }
    }

    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("暂无历史对比")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("开始对比后，项目会自动保存到这里")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - 项目列表视图
    private var projectListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(projects) { project in
                    ProjectCard(project: project) {
                        onLoadProject(project.id)
                        dismiss()
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            projectToDelete = project
                            showDeleteAlert = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - 方法
    private func loadProjects() {
        isLoading = true

        ProjectStorage.shared.loadAllMetadata { result in
            isLoading = false

            switch result {
            case .success(let metadataList):
                // 按更新时间降序排序
                projects = metadataList.sorted { $0.updatedAt > $1.updatedAt }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteProject(_ project: ProjectMetadata) {
        ProjectStorage.shared.deleteProject(id: project.id) { result in
            switch result {
            case .success:
                // 从列表中移除
                withAnimation {
                    projects.removeAll { $0.id == project.id }
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - 项目卡片
struct ProjectCard: View {
    let project: ProjectMetadata
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                // 缩略图
                if let thumbnailData = project.thumbnailData,
                   let thumbnail = UIImage(data: thumbnailData) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                }

                // 项目信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(project.layerCount) 个图层")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(updateTimeText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var updateTimeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: project.updatedAt, relativeTo: Date())
    }
}

#Preview {
    ProjectHistoryView { _ in }
}
