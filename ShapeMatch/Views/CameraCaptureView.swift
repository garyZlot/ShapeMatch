//
//  CameraCaptureView.swift
//  ShapeMatch
//
//  相机拍照视图 - 支持遮罩对齐功能
//

import SwiftUI
import AVFoundation
import UIKit
import Combine

// MARK: - 单次拍摄相机视图（支持叠加遮罩）
struct SingleCameraCaptureView: View {
    let overlayImage: UIImage?
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool

    @StateObject private var camera = CameraModel()

    var body: some View {
        ZStack {
            // 相机预览
            CameraPreview(camera: camera)
                .ignoresSafeArea()

            // 叠加图片作为半透明遮罩
            if let overlay = overlayImage {
                Image(uiImage: overlay)
                    .resizable()
                    .scaledToFit()
                    .opacity(0.4)
                    .allowsHitTesting(false)
            }

            // 控制界面
            VStack {
                Spacer()

                // 顶部提示
                if let _ = overlayImage {
                    Text("将画面对齐到半透明遮罩")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                }

                // 底部控制按钮
                HStack(spacing: 30) {
                    // 取消按钮
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }

                    // 拍照按钮
                    Button {
                        camera.takePhoto { image in
                            capturedImage = image
                            isPresented = false
                        }
                    } label: {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                            )
                    }

                    // 闪光灯按钮
                    Button {
                        camera.toggleFlash()
                    } label: {
                        Image(systemName: camera.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title2)
                            .foregroundStyle(camera.flashMode == .on ? .yellow : .white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            camera.checkPermission()
        }
        .onDisappear {
            camera.stopSession()
        }
    }
}

// MARK: - 相机模型
class CameraModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off

    private var photoCompletion: ((UIImage?) -> Void)?

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    self.setUp()
                }
            }
        case .denied:
            alert.toggle()
        default:
            return
        }
    }

    func setUp() {
        do {
            self.session.beginConfiguration()

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }

            let input = try AVCaptureDeviceInput(device: device)

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }

            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }

            self.session.commitConfiguration()

            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    func takePhoto(completion: @escaping (UIImage?) -> Void) {
        self.photoCompletion = completion

        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode

        self.output.capturePhoto(with: settings, delegate: self)
    }

    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                if flashMode == .on {
                    flashMode = .off
                } else {
                    flashMode = .on
                }
                device.unlockForConfiguration()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()
        }
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            photoCompletion?(nil)
            return
        }

        if let data = photo.fileDataRepresentation(),
           let image = UIImage(data: data) {
            photoCompletion?(image)
        } else {
            photoCompletion?(nil)
        }
    }
}

// MARK: - 相机预览视图
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)

        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview?.frame = view.frame
        camera.preview?.videoGravity = .resizeAspectFill

        view.layer.addSublayer(camera.preview!)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

#Preview {
    SingleCameraCaptureView(
        overlayImage: nil,
        capturedImage: .constant(nil),
        isPresented: .constant(true)
    )
}
