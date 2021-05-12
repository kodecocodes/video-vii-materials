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

// MARK: - Sort a tuple with 2 comparable elements
public func sort<Comparable: Swift.Comparable>(
  _ comparable0: Comparable, _ comparable1: Comparable
) -> (Comparable, Comparable) {
  comparable0 <= comparable1
    ? (comparable0, comparable1)
    : (comparable1, comparable0)
}

enum BodyPose: String {
  case pray = "🙏"
  case shrug = "🤷‍♀️"
  case muscle = "💪"
  case unsure = ""

  // MARK: - Evaluate Body Pose
  static func evaluateBodyPose(from bodyLandmarks: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint]) -> BodyPose {
    guard
      let leftWrist = bodyLandmarks[.leftWrist],
      let leftElbow = bodyLandmarks[.leftElbow],
      let leftShoulder = bodyLandmarks[.leftShoulder],
      let rightWrist = bodyLandmarks[.rightWrist],
      let rightElbow = bodyLandmarks[.rightElbow],
      let rightShoulder = bodyLandmarks[.rightShoulder]
    else { return .unsure }
    
    let pose: BodyPose
    
    if leftWrist.distance(rightWrist) < 0.2
        && ClosedRange(uncheckedBounds: sort(leftShoulder.x, rightShoulder.x)).contains(leftWrist.x) {
      pose = .pray
    } else if leftWrist.y > leftElbow.y
                && rightWrist.y > rightElbow.y
                && leftWrist.x.distance(to: leftElbow.x) < 0.15
                && rightWrist.x.distance(to: rightElbow.x) < 0.15 {
      pose = .shrug
    } else if rightWrist.y > rightElbow.y
                && -0.3...0.3 ~= normalizedDotProduct(
                  origin: rightElbow.location,
                  joints: (rightWrist.location, rightShoulder.location)
                ) {
      pose = .muscle
    } else {
      pose = .unsure
    }
    
    return pose
  }
}
