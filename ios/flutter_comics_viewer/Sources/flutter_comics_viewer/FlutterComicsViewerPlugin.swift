import Flutter
import UIKit
// TODO: Uncomment when ComicsViewer package is added
// import ComicsViewer

public class FlutterComicsViewerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_comics_viewer", binaryMessenger: registrar.messenger())
        let instance = FlutterComicsViewerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Register platform view factory
        let factory = ComicsViewerFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "flutter_comics_viewer")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

/// Factory for creating ComicsViewerPlatformView instances
class ComicsViewerFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return ComicsViewerPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
