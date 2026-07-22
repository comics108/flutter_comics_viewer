import Flutter
import UIKit
// TODO: Uncomment when ComicsViewer package is added to the app
// import ComicsViewer

class ComicsViewerPlatformView: NSObject, FlutterPlatformView {
    private let _view: UIView
    private let methodChannel: FlutterMethodChannel

    // TODO: Uncomment when ComicsViewer is available
    // private let imageScrollView: ImageScrollView

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

        super.init()

        // Extract creation parameters
        if let arguments = args as? [String: Any] {
            filePath = arguments["filePath"] as? String
            languageIndex = arguments["languageIndex"] as? Int ?? 0
            soundEnabled = arguments["soundEnabled"] as? Bool ?? true
        }

        // TODO: Initialize ImageScrollView from ComicsViewer package
        /*
        imageScrollView = ImageScrollView()
        imageScrollView.isComics = true
        imageScrollView.languageIndex = languageIndex
        imageScrollView.soundEnabled = soundEnabled
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false

        _view.addSubview(imageScrollView)
        NSLayoutConstraint.activate([
            imageScrollView.topAnchor.constraint(equalTo: _view.topAnchor),
            imageScrollView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            imageScrollView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            imageScrollView.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])

        // Load comics if file path is provided
        if let path = filePath {
            loadComics(path: path)
        }
        */

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
            // TODO: Implement play functionality
            // imageScrollView.resumeSounds()
            result(nil)

        case "pause":
            // TODO: Implement pause functionality
            // imageScrollView.pauseSounds()
            result(nil)

        case "setScrollPosition":
            guard let args = call.arguments as? [String: Any],
                  let position = args["position"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Position is required", details: nil))
                return
            }
            // TODO: Set scroll position
            // let scrollY = CGFloat(position) * imageScrollView.contentSize.height
            // imageScrollView.setContentOffset(CGPoint(x: 0, y: scrollY), animated: false)
            result(nil)

        case "getScrollPosition":
            // TODO: Get scroll position
            // let position = Double(imageScrollView.contentOffset.y / imageScrollView.contentSize.height)
            // result(position)
            result(0.0)

        case "setLanguageIndex":
            guard let args = call.arguments as? [String: Any],
                  let index = args["index"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Index is required", details: nil))
                return
            }
            languageIndex = index
            // TODO: Update language
            // imageScrollView.languageIndex = index
            // imageScrollView.reloadLanguage()
            result(nil)

        case "setSoundEnabled":
            guard let args = call.arguments as? [String: Any],
                  let enabled = args["enabled"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Enabled flag is required", details: nil))
                return
            }
            soundEnabled = enabled
            // TODO: Update sound enabled
            // imageScrollView.soundEnabled = enabled
            result(nil)

        case "setMuted":
            guard let args = call.arguments as? [String: Any],
                  let muted = args["muted"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Muted flag is required", details: nil))
                return
            }
            // TODO: Mute/unmute
            // imageScrollView.mute(muted)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func loadComics(path: String) {
        // TODO: Load comics using ArchiveManager and ImageScrollView
        /*
        let fileURL = URL(fileURLWithPath: path)
        ArchiveManager.shared.currentArchiveURL = fileURL

        ArchiveManager.shared.comics { [weak self] comics in
            guard let self = self, let comics = comics else { return }
            DispatchQueue.main.async {
                self.imageScrollView.comics = comics
            }
        }
        */
    }

    deinit {
        methodChannel.setMethodCallHandler(nil)
    }
}
