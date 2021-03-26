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
import Vision

final class CameraViewController: UIViewController {
  // swiftlint:disable:next force_cast
  private var cameraView: CameraPreview { view as! CameraPreview }
  
  private let videoDataOutputQueue = DispatchQueue(
    label: "CameraFeedOutput",
    qos: .userInteractive
  )
  private var cameraFeedSession: AVCaptureSession?
  
  private let handPoseRequest: VNDetectHumanHandPoseRequest = {
    let request = VNDetectHumanHandPoseRequest()
    request.maximumHandCount = 2
    return request
  }()
  
  var pointsProcessorHandler: ((_ points: [CGPoint], _ gestures: [HandGesture]) -> Void)?
  
  override func loadView() {
    view = CameraPreview()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    do {
      if cameraFeedSession == nil {
        try setupAVSession()
        cameraView.previewLayer.session = cameraFeedSession
        cameraView.previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.currentInterfaceOrientation
        cameraView.previewLayer.videoGravity = .resizeAspectFill
      }
      cameraFeedSession?.startRunning()
    } catch {
      print(error.localizedDescription)
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    cameraFeedSession?.stopRunning()
    super.viewWillDisappear(animated)
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    cameraView.previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.currentInterfaceOrientation
    super.viewWillTransition(to: size, with: coordinator)
  }
  
  func setupAVSession() throws {
    // Select a front facing camera, make an input.
    guard let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front)
    else {
      throw AppError.captureSessionSetup(
        reason: "Could not find a front facing camera."
      )
    }
    
    guard let deviceInput = try? AVCaptureDeviceInput(
      device: videoDevice
    ) else {
      throw AppError.captureSessionSetup(
        reason: "Could not create video device input."
      )
    }
    
    let session = AVCaptureSession()
    session.beginConfiguration()
    session.sessionPreset = AVCaptureSession.Preset.high
    
    // Add a video input.
    guard session.canAddInput(deviceInput) else {
      throw AppError.captureSessionSetup(
        reason: "Could not add video device input to the session"
      )
    }
    session.addInput(deviceInput)
    
    let dataOutput = AVCaptureVideoDataOutput()
    if session.canAddOutput(dataOutput) {
      session.addOutput(dataOutput)
      // Add a video data output.
      dataOutput.alwaysDiscardsLateVideoFrames = true
      dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    } else {
      throw AppError.captureSessionSetup(
        reason: "Could not add video data output to the session"
      )
    }
    session.commitConfiguration()
    cameraFeedSession = session
  }
  
  func processPoints(fingerTips: [CGPoint], gestures: [HandGesture]) {
    // Convert points from AVFoundation coordinates to UIKit coordinates.
    let convertedPoints = fingerTips.map {
      cameraView.previewLayer.layerPointConverted(fromCaptureDevicePoint: $0)
    }
    pointsProcessorHandler?(convertedPoints, gestures)
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    var fingerTips: [CGPoint] = []
    var gestures: [HandGesture] = [.unsure]
    
    defer {
      DispatchQueue.main.sync {
        self.processPoints(fingerTips: fingerTips, gestures: gestures)
      }
    }
    
    let handler = VNImageRequestHandler(
      cmSampleBuffer: sampleBuffer,
      orientation: .up,
      options: [:]
    )
    do {
      // Perform VNDetectHumanHandPoseRequest
      try handler.perform([handPoseRequest])
      
      // Continue only when at least a hand was detected in the frame. We're interested in maximum of two hands.
      guard
        let results = handPoseRequest.results?.prefix(2),
        !results.isEmpty
      else {
        return
      }
      
      var recognizedPoints: [VNRecognizedPoint] = []
      
      try results.forEach { observation in
        // MARK: Get points for all fingers
        let handLandmarks = try observation.recognizedPoints(.all)
          // Filter out low confidence results
          .filter { joint in
            joint.value.confidence > 0.5
          }
        
        // MARK: Look for tips
        let tipPoints: [VNHumanHandPoseObservation.JointName] = [.thumbTip, .indexTip, .middleTip, .ringTip, .littleTip]
        let recognizedTips = tipPoints
          .compactMap { handLandmarks[$0] }
        
        // MARK: Add the recognized tips
        recognizedPoints += recognizedTips
        
        // MARK: Add recognized gesture
        gestures.append(HandGesture.evaluateHandPose(from: handLandmarks))
      }
      
      // MARK: Convert & store recognized points
      fingerTips = recognizedPoints.map {
        // Convert points from Vision coordinates to AVFoundation coordinates.
        CGPoint(x: $0.location.x, y: 1 - $0.location.y)
      }
    } catch {
      cameraFeedSession?.stopRunning()
      print(error.localizedDescription)
    }
  }
  

}

// MARK: - Extensions
extension AVCaptureVideoOrientation {
  static var currentInterfaceOrientation: AVCaptureVideoOrientation {
    let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
    
    switch interfaceOrientation {
    case .portrait:
      return AVCaptureVideoOrientation.portrait
    case .landscapeLeft:
      return AVCaptureVideoOrientation.landscapeLeft
    case .landscapeRight:
      return AVCaptureVideoOrientation.landscapeRight
    case .portraitUpsideDown:
      return AVCaptureVideoOrientation.portraitUpsideDown
    default:
      return AVCaptureVideoOrientation.portrait
    }
  }
}
