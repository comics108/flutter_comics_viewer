package net.nativemind.flutter.comics.viewer

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** FlutterComicsViewerPlugin */
class FlutterComicsViewerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = binding

        // Setup method channel
        channel = MethodChannel(binding.binaryMessenger, "flutter_comics_viewer")
        channel.setMethodCallHandler(this)

        // Register platform view
        binding.platformViewRegistry.registerViewFactory(
            "flutter_comics_viewer",
            ComicsViewerFactory(binding.binaryMessenger)
        )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            // These methods will be handled by the platform view
            // They're here for non-view operations if needed
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

/** Factory for creating ComicsViewerPlatformView instances */
class ComicsViewerFactory(
    private val messenger: io.flutter.plugin.common.BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(
        context: android.content.Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        val creationParams = args as? Map<String, Any>
        return ComicsViewerPlatformView(context, viewId, creationParams, messenger)
    }
}
