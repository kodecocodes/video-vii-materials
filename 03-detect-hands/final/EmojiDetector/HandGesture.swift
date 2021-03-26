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

import Vision

enum HandGesture: String {
  case five = "Five 👋"
  case metal = "Rock On 🤘"
  case peace = "Peace ✌️"
  case callMe = "Call Me 🤙"
  case pointing = "Pointing ☝️"
  case thumbsUp = "Thumbs Up 👍"
  case fist = "Fist ✊"
  case unsure
  
  // MARK: - Evaluate Hand Pose
  static func evaluateHandPose(from handLandmarks: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]) -> HandGesture {
    // We need the wrist to evaluate all of our gestures
    guard handLandmarks[.wrist] != nil else { return .unsure }
    
    // Match sets of extended finger to gestures
    switch Finger.getExtendedFingers(from: handLandmarks) {
    case Set(Finger.allCases):
      return .five
    case [.index, .little]:
      return .metal
    case [.index, .middle]:
      return .peace
    case [.thumb, .little]:
      return .callMe
    case [.index]:
      return .pointing
    case [.thumb]:
      return .thumbsUp
    case []:
      return .fist
    default:
      return .unsure
    }
  }
}
