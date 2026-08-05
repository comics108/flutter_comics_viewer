package net.nativemind.flutter.comics.viewer

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import android.widget.ScrollView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

import net.nativemind.comics.viewer.ComicsViewController
import net.nativemind.comics.viewer.comics.view.LayersView

/**
 * Platform view that displays the comics viewer
 */
class ComicsViewerPlatformView(
    private val context: Context,
    id: Int,
    creationParams: Map<String, Any>?,
    messenger: BinaryMessenger
) : PlatformView, MethodChannel.MethodCallHandler {

    private val containerView: FrameLayout = FrameLayout(context)
    private val methodChannel: MethodChannel = MethodChannel(messenger, "flutter_comics_viewer_$id")

    private val scrollView: ScrollView = ScrollView(context)
    private lateinit var layersView: LayersView
    private lateinit var controller: ComicsViewController

    private var filePath: String? = null
    private var languageIndex: Int = 0
    private var soundEnabled: Boolean = true
    private var muted: Boolean = false

    init {
        methodChannel.setMethodCallHandler(this)

        // Extract creation parameters
        filePath = creationParams?.get("filePath") as? String
        languageIndex = (creationParams?.get("languageIndex") as? Int) ?: 0
        soundEnabled = (creationParams?.get("soundEnabled") as? Boolean) ?: true

        // Initialize views
        layersView = LayersView(context, null)

        scrollView.addView(
            layersView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            )
        )

        containerView.addView(
            scrollView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        // Initialize controller
        controller = ComicsViewController(context, layersView)

        // Setup scroll listener
        controller.setScrollListener { position ->
            methodChannel.invokeMethod("onScrollChanged", mapOf("position" to position))
        }

        // Load comics if file path is provided
        filePath?.let { path ->
            loadComics(path)
        }
    }

    override fun getView(): View = containerView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadComics" -> {
                val path = call.argument<String>("filePath")
                val requestId = call.argument<Int>("requestId")
                if (path != null) {
                    loadComics(path, requestId)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "File path is required", null)
                }
            }
            "play" -> {
                controller.play()
                result.success(null)
            }
            "pause" -> {
                controller.pause()
                result.success(null)
            }
            "setScrollPosition" -> {
                val position = call.argument<Double>("position")
                if (position != null) {
                    controller.setScrollPosition(position.toFloat())
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Position is required", null)
                }
            }
            "getScrollPosition" -> {
                val position = controller.getScrollPosition()
                result.success(position.toDouble())
            }
            "togglePreview" -> {
                val show = call.argument<Boolean>("show")
                if (show != null) {
                    controller.togglePreview(show)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Show flag is required", null)
                }
            }
            "setSoundEnabled" -> {
                val enabled = call.argument<Boolean>("enabled")
                if (enabled != null) {
                    soundEnabled = enabled
                    applySoundState()
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Enabled flag is required", null)
                }
            }
            "setMuted" -> {
                val value = call.argument<Boolean>("muted")
                if (value != null) {
                    muted = value
                    applySoundState()
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Muted flag is required", null)
                }
            }
            "setLanguageIndex" -> {
                val index = call.argument<Int>("index")
                if (index != null) {
                    controller.setLanguage(index)
                    languageIndex = index
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Language index is required", null)
                }
            }
            "isPlaying" -> {
                result.success(controller.isPlaying())
            }
            "getDuration" -> {
                result.success(controller.getDuration().toDouble())
            }
            "getCurrentPosition" -> {
                result.success(controller.getCurrentPosition().toDouble())
            }
            else -> result.notImplemented()
        }
    }

    private fun applySoundState() {
        controller.toggleSounds(soundEnabled && !muted)
    }

    private fun loadComics(path: String, requestId: Int? = null) {
        controller.loadComics(path, object : ComicsViewController.ComicsLoadListener {
            override fun onLoaded() {
                methodChannel.invokeMethod("onLoaded", mapOf("requestId" to requestId))
            }

            override fun onError(error: String) {
                methodChannel.invokeMethod(
                    "onError",
                    mapOf("error" to error, "requestId" to requestId)
                )
            }
        })
    }

    override fun dispose() {
        controller.dispose()
        methodChannel.setMethodCallHandler(null)
    }
}
