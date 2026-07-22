#include "include/viewer/viewer_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "viewer_plugin.h"

void ViewerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  viewer::ViewerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
