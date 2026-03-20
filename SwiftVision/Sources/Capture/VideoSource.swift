import Foundation

public protocol VideoSourceDelegate: AnyObject {
    func videoSource(_ source: any VideoSource, didOutput frame: VideoFrame)
    func videoSource(_ source: any VideoSource, didFail error: Error)
}

public protocol VideoSource: AnyObject {
    var delegate: (any VideoSourceDelegate)? { get set }
    func start() throws
    func stop()
}
