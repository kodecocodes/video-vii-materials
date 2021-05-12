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

import SwiftUI

struct ContentView: View {
  @State private var overlayPoints: [CGPoint] = []
  @State private var emojiPoses: [HandPose] = []
  
  @State private var bodyPoints: [CGPoint] = []
  @State private var bodyPose = BodyPose.unsure
  
  var body: some View {
    ZStack(alignment: .top) {
      CameraView { points, poses in
        overlayPoints = points
        emojiPoses = poses
      }
      bodyPointsProcessor: { points, pose in
        bodyPoints = points
        bodyPose = pose
      }
      .overlay(
        FingersOverlay(with: overlayPoints)
          .foregroundColor(.orange)
      )
      .overlay(
        BodyOverlay(with: bodyPoints)
          .foregroundColor(.purple)
      )
      .edgesIgnoringSafeArea(.all)
      
      VStack(spacing: 20) {
        Text(concatenateEmoji(poses: emojiPoses))
          .font(.largeTitle)
        Spacer()
        Text(bodyPose.rawValue)
          .font(Font.system(size: 100))
      }
    }
  }
  
  func concatenateEmoji(poses: [HandPose]) -> String {
    poses.reduce(into: "") { string, pose in
      switch pose {
      case .unsure:
        return
      default:
        string += " " + pose.rawValue
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
