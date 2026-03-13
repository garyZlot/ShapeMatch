//
//  ProjectStorage.swift
//  ShapeMatch
//
//  项目存储管理 - 保存和加载项目配置
//

import UIKit

// MARK: - 项目数据模型
struct ProjectData: Codable, Identifiable {
    let id: UUID
    let name: String
    let layers: [LayerData]
    let createdAt: Date
    let updatedAt: Date

    struct LayerData: Codable {
        let id: UUID
        let name: String
        let imageData: Data
        let position: PositionData
        let scale: Double
        let opacity: Double
        let rotation: Double
        let isVisible: Bool
        let isLocked: Bool

        struct PositionData: Codable {
            let width: Double
            let height: Double
        }
    }
}

// MARK: - 项目元数据（用于列表显示）
struct ProjectMetadata: Identifiable, Codable {
    let id: UUID
    let name: String
    let thumbnailData: Data?
    let createdAt: Date
    let updatedAt: Date
    let layerCount: Int
}

// MARK: - 存储管理器
class ProjectStorage {
    static let shared = ProjectStorage()

    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let projectsDirectory: URL

    // 图片压缩质量（0.0-1.0）
    private let compressionQuality: CGFloat = 0.8
    private let thumbnailQuality: CGFloat = 0.3

    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        projectsDirectory = documentsDirectory.appendingPathComponent("Projects")

        // 创建 Projects 目录
        try? fileManager.createDirectory(at: projectsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - 文件路径
    private func projectFileURL(for id: UUID) -> URL {
        projectsDirectory.appendingPathComponent("\(id.uuidString).json")
    }

    private var metadataFileURL: URL {
        documentsDirectory.appendingPathComponent("projects_metadata.json")
    }

    // MARK: - 保存项目
    func saveProject(
        id: UUID,
        name: String,
        layers: [Layer],
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }

                // 转换图层数据
                let layerDataList = try self.convertLayersToData(layers)

                // 获取或创建项目元数据
                let now = Date()
                var metadata = ProjectMetadata(
                    id: id,
                    name: name,
                    thumbnailData: layerDataList.first?.imageData,
                    createdAt: now,
                    updatedAt: now,
                    layerCount: layers.count
                )

                // 如果是更新已有项目，保留创建时间
                let existingMetadata = try? self.loadAllMetadataSync().first { $0.id == id }
                if let existing = existingMetadata {
                    metadata = ProjectMetadata(
                        id: id,
                        name: name,
                        thumbnailData: existing.thumbnailData,
                        createdAt: existing.createdAt,
                        updatedAt: now,
                        layerCount: layers.count
                    )
                }

                // 创建项目数据
                let projectData = ProjectData(
                    id: id,
                    name: name,
                    layers: layerDataList,
                    createdAt: metadata.createdAt,
                    updatedAt: now
                )

                // 编码为 JSON
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let jsonData = try encoder.encode(projectData)

                // 写入项目文件
                let fileURL = self.projectFileURL(for: id)
                try jsonData.write(to: fileURL, options: .atomic)

                // 更新元数据 - 保留所有现有项目，添加或更新当前项目
                var allMetadata = try self.loadAllMetadataSync()
                // 移除同 ID 的旧元数据（如果有）
                allMetadata.removeAll { $0.id == id }
                // 添加新的元数据
                allMetadata.append(metadata)
                self.updateMetadata(allMetadata)

                DispatchQueue.main.async {
                    completion?(.success(()))
                    print("✅ 项目已保存: \(name)")
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(.failure(error))
                    print("❌ 保存项目失败: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 加载单个项目
    func loadProject(id: UUID, completion: @escaping (Result<ProjectData, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else {
                    DispatchQueue.main.async {
                        completion(.failure(StorageError.unknown))
                    }
                    return
                }

                let fileURL = self.projectFileURL(for: id)

                guard self.fileManager.fileExists(atPath: fileURL.path) else {
                    DispatchQueue.main.async {
                        completion(.failure(StorageError.fileNotFound))
                    }
                    return
                }

                let jsonData = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                let projectData = try decoder.decode(ProjectData.self, from: jsonData)

                DispatchQueue.main.async {
                    completion(.success(projectData))
                    print("✅ 项目已加载: \(projectData.name)")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                    print("❌ 加载项目失败: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 加载所有项目元数据
    func loadAllMetadata(completion: @escaping (Result<[ProjectMetadata], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else {
                    DispatchQueue.main.async {
                        completion(.failure(StorageError.unknown))
                    }
                    return
                }

                let metadata = try self.loadAllMetadataSync()

                DispatchQueue.main.async {
                    completion(.success(metadata))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - 同步加载所有元数据
    private func loadAllMetadataSync() throws -> [ProjectMetadata] {
        guard fileManager.fileExists(atPath: metadataFileURL.path) else {
            return []
        }

        let jsonData = try Data(contentsOf: metadataFileURL)
        let decoder = JSONDecoder()
        return try decoder.decode([ProjectMetadata].self, from: jsonData)
    }

    // MARK: - 更新元数据
    private func updateMetadata(_ metadataList: [ProjectMetadata]) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let self = self else { return }

                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let jsonData = try encoder.encode(metadataList)
                try jsonData.write(to: self.metadataFileURL, options: .atomic)
            } catch {
                print("❌ 更新元数据失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 删除项目
    func deleteProject(id: UUID, completion: ((Result<Void, Error>) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let self = self else { return }

                let fileURL = self.projectFileURL(for: id)

                if self.fileManager.fileExists(atPath: fileURL.path) {
                    try self.fileManager.removeItem(at: fileURL)
                }

                // 从元数据中移除
                var metadataList = try self.loadAllMetadataSync()
                metadataList.removeAll { $0.id == id }
                self.updateMetadata(metadataList)

                DispatchQueue.main.async {
                    completion?(.success(()))
                    print("✅ 项目已删除")
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(.failure(error))
                    print("❌ 删除项目失败: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 辅助方法：转换图层数据
    private func convertLayersToData(_ layers: [Layer]) throws -> [ProjectData.LayerData] {
        try layers.map { layer in
            // 压缩图片数据
            guard let imageData = layer.image.jpegData(compressionQuality: compressionQuality) else {
                throw StorageError.imageCompressionFailed
            }

            return ProjectData.LayerData(
                id: layer.id,
                name: layer.name,
                imageData: imageData,
                position: ProjectData.LayerData.PositionData(
                    width: Double(layer.position.width),
                    height: Double(layer.position.height)
                ),
                scale: Double(layer.scale),
                opacity: layer.opacity,
                rotation: layer.rotation,
                isVisible: layer.isVisible,
                isLocked: layer.isLocked
            )
        }
    }

    // MARK: - 辅助方法：从数据恢复图层
    func restoreLayers(from projectData: ProjectData) -> [Layer] {
        projectData.layers.map { layerData in
            guard let image = UIImage(data: layerData.imageData) else {
                return Layer(
                    name: layerData.name,
                    image: UIImage(systemName: "photo") ?? UIImage(),
                    position: CGSize(
                        width: layerData.position.width,
                        height: layerData.position.height
                    ),
                    scale: CGFloat(layerData.scale),
                    opacity: layerData.opacity,
                    isVisible: layerData.isVisible,
                    isLocked: layerData.isLocked,
                    rotation: layerData.rotation
                )
            }

            return Layer(
                name: layerData.name,
                image: image,
                position: CGSize(
                    width: layerData.position.width,
                    height: layerData.position.height
                ),
                scale: CGFloat(layerData.scale),
                opacity: layerData.opacity,
                isVisible: layerData.isVisible,
                isLocked: layerData.isLocked,
                rotation: layerData.rotation
            )
        }
    }

    // MARK: - 生成缩略图
    func generateThumbnail(from image: UIImage) -> Data? {
        // 缩放到 200x200
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return thumbnail?.jpegData(compressionQuality: thumbnailQuality)
    }
}

// MARK: - 存储错误
enum StorageError: LocalizedError {
    case fileNotFound
    case imageCompressionFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "未找到保存的项目"
        case .imageCompressionFailed:
            return "图片压缩失败"
        case .unknown:
            return "未知错误"
        }
    }
}
