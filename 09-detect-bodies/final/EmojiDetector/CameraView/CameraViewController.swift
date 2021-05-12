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
  private let cameraCaptureSession = AVCaptureSession()
  private var cameraPreview: CameraPreview { view as! CameraPreview }

  private let videoDataOutputQueue = DispatchQueue(
    label: "CameraFeedOutput", qos: .userInteractive
  )
  
  private let handPoseRequest: VNDetectHumanHandPoseRequest = {
    let request = VNDetectHumanHandPoseRequest()
    request.maximumHandCount = 2
    return request
  }()
  
  // TODO: - Add a body pose request
  private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
  
  var pointsProcessor: ((_ points: [CGPoint], _ poses: [HandPose]) -> Void)?
  var bodyPointsProcessor: ((_ points: [CGPoint], _ pose: BodyPose) -> Void)?
  
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
  
  func setupPreview() {
    cameraPreview.previewLayer.session = cameraCaptureSession
    cameraPreview.previewLayer.videoGravity = .resizeAspectFill
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
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    var recognizedPoints: [VNRecognizedPoint] = []
    var poses: [HandPose] = []
    
    var recognizedBodyPoints: [VNRecognizedPoint] = []
    var bodyPose = BodyPose.unsure

    func convertPoint(_ point: VNRecognizedPoint) -> CGPoint {
      let cgPoint = CGPoint(x: 1 - point.y, y: 1 - point.x)
      return cameraPreview.previewLayer.layerPointConverted(fromCaptureDevicePoint: cgPoint)
    }

    defer {
      DispatchQueue.main.sync {
        let convertedPoints = recognizedPoints.map(convertPoint(_:))
        pointsProcessor?(convertedPoints, poses)
        
        let convertedBodyPoints = recognizedBodyPoints.map(convertPoint(_:))
        bodyPointsProcessor?(convertedBodyPoints, bodyPose)
      }
    }
    
    // TODO: -  Reuse this image request handler
    let handler = VNImageRequestHandler(
      cmSampleBuffer: sampleBuffer,
      orientation: .right,
      options: [:]
    )
    
    do {
      try handler.perform([handPoseRequest, bodyPoseRequest])
      
      // TODO: - Process the body pose request observations
      if let bodyPoseResults = bodyPoseRequest.results?.first {
        let armJoints: [VNHumanBodyPoseObservation.JointName] = [.leftWrist, .leftElbow, .leftShoulder, .rightShoulder, .rightElbow, .rightWrist]
        
        let armLandmarks = try bodyPoseResults.recognizedPoints(.all)
          .filter { armJoints.contains($0.key) }
          .filter { $0.value.confidence > 0.3 }
        
        bodyPose = BodyPose.evaluateBodyPose(from: armLandmarks)
        recognizedBodyPoints = Array(armLandmarks.values)
      }
      
      guard
        let results = handPoseRequest.results?.prefix(2),
        !results.isEmpty
      else { return }
      
      try results.forEach { observation in
        let handLandmarks = try observation.recognizedPoints(.all)
          .filter { point in
            point.value.confidence > 0.6
          }
        
        let tipPoints: [VNHumanHandPoseObservation.JointName] = [.thumbTip, .indexTip, .middleTip, .ringTip, .littleTip]
        let recognizedTips = tipPoints
          .compactMap { handLandmarks[$0] }
        
        recognizedPoints += recognizedTips
        
        poses.append(HandPose.evaluateHandPose(from: handLandmarks))
      }
    } catch {
      cameraCaptureSession.stopRunning()
      print(error.localizedDescription)
    }
  }
}
