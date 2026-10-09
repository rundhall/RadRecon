#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // Az Impeller renderer néhány (főleg gyengébb/virtuális GPU-driveres,
  // pl. RDP-n át futó) Windows gépen sosem tudja lerenderelni az első
  // képkockát, és mivel az ablak csak az első képkocka után jelenik meg
  // (lásd flutter_window.cpp SetNextFrameCallback), a program a felhasználó
  // szemében örökre "beakad" (homokóra, ablak nélkül), miközben a Dart-kód
  // valójában végigfutott. A régebbi, sokkal szélesebb kompatibilitású
  // OpenGL/Skia renderert kényszerítjük ki helyette.
  command_line_arguments.push_back("--enable-impeller=false");

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"rad_recon", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
