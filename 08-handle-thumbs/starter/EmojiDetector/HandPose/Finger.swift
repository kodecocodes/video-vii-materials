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

import CoreGraphics
import simd
import Vision

enum Finger: Hashable, CaseIterable {
  case index
  case middle
  case ring
  case little
  case thumb
  
  // TODO: - Add a method to handle the thumb
  
  static func extends(tip: VNRecognizedPoint?, pip: VNRecognizedPoint?, wrist: VNRecognizedPoint) -> Bool {
    guard let tip = tip,
          let pip = pip
    else { return false }
    
    return tip.distance(wrist) > pip.distance(wrist)
  }
  
  static func getExtendedFingers(from handLandmarks: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]) -> Set<Finger> {
    guard let wrist = handLandmarks[.wrist] else { return [] }
    
    let fingers = Finger.allCases.filter { finger in
      switch finger {
      case .index:
        return extends(tip: handLandmarks[.indexTip], pip: handLandmarks[.indexPIP], wrist: wrist)
      case .middle:
        return extends(tip: handLandmarks[.middleTip], pip: handLandmarks[.middlePIP], wrist: wrist)
      case .ring:
        return extends(tip: handLandmarks[.ringTip], pip: handLandmarks[.ringPIP], wrist: wrist)
      case .little:
        return extends(tip: handLandmarks[.littleTip], pip: handLandmarks[.littlePIP], wrist: wrist)
      case .thumb:
        // TODO: - Call the new thumb method
        return false
      }
    }
    
    return Set(fingers)
  }
}


// MARK: - Extensions
func normalizedDotProduct(origin: CGPoint, joints: (CGPoint, CGPoint)) -> Double {
  let origin = SIMD2(origin)
  return dot(
    normalize(SIMD2(joints.0) - origin),
    normalize(SIMD2(joints.1) - origin)
  )
}

extension SIMD2 where Scalar == CGFloat.NativeType {
  init(_ point: CGPoint) {
    self.init(x: point.x.native, y: point.y.native)
  }
}
