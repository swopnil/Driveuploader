import SwiftUI
import AVFoundation
import UIKit

struct CameraView: UIViewControllerRepresentable {
    let folderPath: String
    @ObservedObject var queueManager: UploadQueueManager
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.folderPath = folderPath
        controller.queueManager = queueManager
        controller.dismissAction = {
            presentationMode.wrappedValue.dismiss()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    var folderPath: String!
    var queueManager: UploadQueueManager!
    var dismissAction: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        
        if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
            captureSession.addInput(input)
            captureSession.addOutput(photoOutput)
            setupLivePreview()
        }
    }
    
    private func setupLivePreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer)
    }
    
    private func setupUI() {
        // Capture Button
        let captureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        captureButton.layer.cornerRadius = 35
        captureButton.backgroundColor = UIColor.white
        captureButton.layer.borderWidth = 5
        captureButton.layer.borderColor = UIColor.gray.cgColor
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        
        // Cancel Button
        let cancelButton = UIButton(frame: CGRect(x: 20, y: 40, width: 60, height: 40))
        cancelButton.setTitle("Done", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.addTarget(self, action: #selector(dismissCamera), for: .touchUpInside)
        
        // Add buttons to view
        view.addSubview(captureButton)
        view.addSubview(cancelButton)
        
        // Constraints
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        // Provide haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        
        // Visual feedback animation
        if let button = view.subviews.first(where: { $0 is UIButton }) as? UIButton {
            UIView.animate(withDuration: 0.1, animations: {
                button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    button.transform = CGAffineTransform.identity
                }
            }
        }
    }
    
    @objc private func dismissCamera() {
        dismissAction?()
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // Add to upload queue
        queueManager.addToQueue(image: image, path: folderPath)
        
        // Show brief feedback
        showFeedbackToast()
    }
    
    private func showFeedbackToast() {
        let toastView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        toastView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastView.layer.cornerRadius = 25
        
        let label = UILabel(frame: toastView.bounds)
        label.text = "Photo Queued"
        label.textColor = .white
        label.textAlignment = .center
        toastView.addSubview(label)
        
        toastView.center = CGPoint(x: view.center.x, y: view.bounds.height - 150)
        view.addSubview(toastView)
        
        UIView.animate(withDuration: 0.5, delay: 1.0, options: .curveEaseOut) {
            toastView.alpha = 0
        } completion: { _ in
            toastView.removeFromSuperview()
        }
    }
}
