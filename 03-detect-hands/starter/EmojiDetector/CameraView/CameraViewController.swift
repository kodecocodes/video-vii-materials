/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import AVFoundation

final class CameraViewController: UIViewController {
  
  private var cameraCaptureSession = AVCaptureSession()
  private var cameraPreview: CameraPreview { view as! CameraPreview }
  
  private let videoDataOutputQueue = DispatchQueue(
    label: "CameraFeedOutput", qos: .userInteractive
  )
  
  // TODO: - Add a hand pose request
  
  override func loadView() {
    view = CameraPreview()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    setupAVSession()
    setupPreview()
    cameraCaptureSession.startRunning()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    cameraCaptureSession.stopRunning()
    super.viewWillDisappear(animated)
  }
  
  override func viewDidLayoutSubviews() {
    cameraPreview.previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.currentDeviceOrientation
  }
  
  func setupPreview() {
    cameraPreview.previewLayer.session = cameraCaptureSession
    cameraPreview.previewLayer.videoGravity = .resizeAspectFill
    cameraPreview.previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.currentDeviceOrientation
  }
  
  func setupAVSession() {
    // Start session configuration
    cameraCaptureSession.beginConfiguration()
    
    // Setup video data input
    guard
      let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
      let deviceInput = try? AVCaptureDeviceInput(device: videoDevice),
      cameraCaptureSession.canAddInput(deviceInput)
    else { return }
    
    cameraCaptureSession.sessionPreset = AVCaptureSession.Preset.high
    cameraCaptureSession.addInput(deviceInput)
    
    // Setup video data output
    let dataOutput = AVCaptureVideoDataOutput()
    guard cameraCaptureSession.canAddOutput(dataOutput)
    else { return }
    
    cameraCaptureSession.addOutput(dataOutput)
    dataOutput.alwaysDiscardsLateVideoFrames = true
    dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    
    // Commit session configuration
    cameraCaptureSession.commitConfiguration()
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
}

// MARK: - AVCaptureVideoOrientation
extension AVCaptureVideoOrientation {
  static var currentDeviceOrientation: AVCaptureVideoOrientation {
    let deviceOrientation = UIDevice.current.orientation
    
    switch deviceOrientation {
    case .portrait:
      return AVCaptureVideoOrientation.portrait
    case .landscapeLeft:
      return AVCaptureVideoOrientation.landscapeRight
    case .landscapeRight:
      return AVCaptureVideoOrientation.landscapeLeft
    case .portraitUpsideDown:
      return AVCaptureVideoOrientation.portraitUpsideDown
    default:
      return AVCaptureVideoOrientation.portrait
    }
  }
}
