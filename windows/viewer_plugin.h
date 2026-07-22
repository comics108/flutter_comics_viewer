#ifndef FLUTTER_PLUGIN_VIEWER_PLUGIN_H_
#define FLUTTER_PLUGIN_VIEWER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace viewer {

class ViewerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ViewerPlugin();

  virtual ~ViewerPlugin();

  // Disallow copy and assign.
  ViewerPlugin(const ViewerPlugin&) = delete;
  ViewerPlugin& operator=(const ViewerPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace viewer

#endif  // FLUTTER_PLUGIN_VIEWER_PLUGIN_H_
