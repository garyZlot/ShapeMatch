# 添加文件到 Xcode 项目

## 📝 需要添加的文件

请在 Xcode 中添加以下 3 个文件到项目：

1. `ShapeMatch/Services/ImageAlignment/ImageAlignmentProtocol.swift`
2. `ShapeMatch/Services/ImageAlignment/VisionImageAlignment.swift`
3. `ShapeMatch/Services/ImageAlignment/ImageAlignmentService.swift`

## 🔧 添加步骤

### 方法 1: 使用 Xcode (推荐)

1. 在 Xcode 中打开 `ShapeMatch.xcodeproj`
2. 在 Project Navigator 中，找到 `ShapeMatch` 文件夹
3. 展开 `ShapeMatch` → `Services`
4. 选中 `Services` 文件夹
5. 右键点击 → 选择 `Add Files to "ShapeMatch"...`
6. 导航到项目文件夹，选择以下 3 个文件：
   - `ShapeMatch/Services/ImageAlignment/ImageAlignmentProtocol.swift`
   - `ShapeMatch/Services/ImageAlignment/VisionImageAlignment.swift`
   - `ShapeMatch/Services/ImageAlignment/ImageAlignmentService.swift`
7. 确保勾选 "Copy items if needed" 和正确的 target
8. 点击 "Add"

### 方法 2: 拖拽

1. 在 Finder 中找到 `ShapeMatch/Services/ImageAlignment` 文件夹
2. 将这 3 个 `.swift` 文件拖拽到 Xcode 的 Project Navigator 中
3. 拖拽到 `Services` 文件夹下
4. 在弹出的对话框中，确保：
   - ✅ 勾选 "Copy items if needed"
   - ✅ 勾选 "Create groups"
   - ✅ 勾选正确的 target (ShapeMatch)
5. 点击 "Finish"

## ✅ 验证

添加完成后，在 Xcode 的 Project Navigator 中应该能看到：

```
ShapeMatch
├── Services
│   ├── ImageAlignment
│   │   ├── ImageAlignmentProtocol.swift  ✅
│   │   ├── VisionImageAlignment.swift    ✅
│   │   └── ImageAlignmentService.swift   ✅
│   ├── ImageComparator.swift
│   └── ProjectStorage.swift
...
```

## 🎯 完成后

文件添加完成后，项目应该可以正常编译和运行。

自动对齐功能会在对比页面的图层面板中显示一个"自动对齐"按钮（魔法棒图标）。
