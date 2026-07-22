import Flutter
import UIKit
import ComicsViewer

class ComicsViewerPlatformView: NSObject, FlutterPlatformView {
    private let _view: UIView
    private let methodChannel: FlutterMethodChannel
    private let imageScrollView: ImageScrollView
    private var controller: ComicsViewerController!

    private var filePath: String?
    private var languageIndex: Int = 0
    private var soundEnabled: Bool = true

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)
        _view.backgroundColor = .black

        methodChannel = FlutterMethodChannel(
            name: "flutter_comics_viewer_\(viewId)",
            binaryMessenger: messenger
        )

        // Initialize ImageScrollView from ComicsViewer package
        imageScrollView = ImageScrollView()
        imageScrollView.isComics = true
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false

        super.init()

        // Extract creation parameters
        if let arguments = args as? [String: Any] {
            filePath = arguments["filePath"] as? String
            languageIndex = arguments["languageIndex"] as? Int ?? 0
            soundEnabled = arguments["soundEnabled"] as? Bool ?? true
        }

        imageScrollView.languageIndex = languageIndex
        imageScrollView.soundEnabled = soundEnabled

        _view.addSubview(imageScrollView)
        NSLayoutConstraint.activate([
            imageScrollView.topAnchor.constraint(equalTo: _view.topAnchor),
            imageScrollView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            imageScrollView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            imageScrollView.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])

        // Initialize controller
        controller = ComicsViewerController(scrollView: imageScrollView)

        // Setup scroll listener
        controller.onScrollChanged = { [weak self] position in
            self?.methodChannel.invokeMethod("onScrollChanged", arguments: ["position": position])
        }

        // Load comics if file path is provided
        if let path = filePath {
            loadComics(path: path)
        }

        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
    }

    func view() -> UIView {
        return _view
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadComics":
            guard let args = call.arguments as? [String: Any],
                  let path = args["filePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "File path is required", details: nil))
                return
            }
            loadComics(path: path)
            result(nil)

        case "play":
            controller.play()
            result(nil)

        case "pause":
            controller.pause()
            result(nil)

        case "setScrollPosition":
            guard let args = call.arguments as? [String: Any],
                  let position = args["position"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Position is required", details: nil))
                return
            }
            controller.setScrollPosition(CGFloat(position))
            result(nil)

        case "getScrollPosition":
            let position = controller.getScrollPosition()
            result(Double(position))

        case "togglePreview":
            guard let args = call.arguments as? [String: Any],
                  let show = args["show"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Show flag is required", details: nil))
                return
            }
            controller.togglePreview(show)
            result(nil)

        case "toggleSounds":
            guard let args = call.arguments as? [String: Any],
                  let enabled = args["enabled"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Enabled flag is required", details: nil))
                return
            }
            controller.toggleSounds(enabled)
            soundEnabled = enabled
            result(nil)

        case "setLanguage":
            guard let args = call.arguments as? [String: Any],
                  let index = args["languageIndex"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Language index is required", details: nil))
                return
            }
            controller.setLanguage(index)
            languageIndex = index
            result(nil)

        case "isPlaying":
            result(controller.isPlaying)

        case "getDuration":
            result(Double(controller.duration))

        case "getCurrentPosition":
            result(Double(controller.currentPosition))

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func loadComics(path: String) {
        controller.loadComics(filePath: path) { [weak self] result in
            switch result {
            case .success:
                self?.methodChannel.invokeMethod("onLoaded", arguments: nil)
            case .failure(let error):
                self?.methodChannel.invokeMethod("onError", arguments: ["error": error.localizedDescription])
            }
        }
    }

    deinit {
        controller.dispose()
        methodChannel.setMethodCallHandler(nil)
    }
}
