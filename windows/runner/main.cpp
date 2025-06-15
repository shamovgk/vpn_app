#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <shellapi.h>

#include "flutter_window.h"
#include "utils.h"

static const int WM_TRAYICON = WM_APP + 1;

NOTIFYICONDATA nid = {0};

void CreateTrayIcon(HWND hwnd) {
  nid.cbSize = sizeof(NOTIFYICONDATA);
  nid.hWnd = hwnd;
  nid.uID = 1;
  nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  nid.uCallbackMessage = WM_TRAYICON;
  nid.hIcon = (HICON)LoadImage(NULL, L"assets\\tray_icon.ico", IMAGE_ICON, 32, 32, LR_LOADFROMFILE);
  wcscpy_s(nid.szTip, L"TowerVPN");
  Shell_NotifyIcon(NIM_ADD, &nid);
}

void ShowContextMenu(HWND hwnd) {
  POINT pt;
  GetCursorPos(&pt);
  HMENU hMenu = CreatePopupMenu();
  MENUITEMINFO mii = {0};
  mii.cbSize = sizeof(MENUITEMINFO);
  mii.fMask = MIIM_STRING | MIIM_FTYPE | MIIM_ID;
  mii.fType = MFT_STRING;
  mii.wID = 1;
  mii.dwTypeData = L"Show Window";
  InsertMenuItem(hMenu, 0, TRUE, &mii);
  mii.wID = 2;
  mii.dwTypeData = L"Connect";
  InsertMenuItem(hMenu, 1, TRUE, &mii);
  mii.wID = 3;
  mii.dwTypeData = L"Disconnect";
  InsertMenuItem(hMenu, 2, TRUE, &mii);
  mii.wID = 4;
  mii.dwTypeData = L"Exit App";
  InsertMenuItem(hMenu, 3, TRUE, &mii);
  SetForegroundWindow(hwnd);
  TrackPopupMenu(hMenu, TPM_RIGHTALIGN | TPM_BOTTOMALIGN, pt.x, pt.y, 0, hwnd, NULL);
  DestroyMenu(hMenu);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
  if (message == WM_TRAYICON) {
    if (lParam == WM_LBUTTONUP || lParam == WM_RBUTTONUP) {
      if (lParam == WM_LBUTTONUP) {
        ShowWindow(hwnd, SW_SHOW);
        SetWindowPos(hwnd, nullptr, 10, 10, 360, 640, SWP_NOZORDER | SWP_NOACTIVATE);
        SetForegroundWindow(hwnd);
      } else if (lParam == WM_RBUTTONUP) {
        ShowContextMenu(hwnd);
      }
    }
    return 0;
  }
  if (message == WM_CLOSE) {
    ShowWindow(hwnd, SW_HIDE); // Скрываем окно вместо закрытия
    return 0;
  }
  if (message == WM_COMMAND) {
    switch (LOWORD(wParam)) {
      case 1: // Show Window
        ShowWindow(hwnd, SW_SHOW);
        SetWindowPos(hwnd, nullptr, 10, 10, 360, 640, SWP_NOZORDER | SWP_NOACTIVATE);
        SetForegroundWindow(hwnd);
        break;
      case 2: // Connect
        SendMessage(hwnd, WM_APP + 2, 0, 0); // Сообщение для подключения
        break;
      case 3: // Disconnect
        SendMessage(hwnd, WM_APP + 3, 0, 0); // Сообщение для отключения
        break;
      case 4: // Exit App
        Shell_NotifyIcon(NIM_DELETE, &nid);
        PostQuitMessage(0); // Завершаем цикл сообщений
        break;
    }
    return 0;
  }
  return DefWindowProc(hwnd, message, wParam, lParam);
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(360, 640); // Фиксированный размер
  if (!window.Create(L"TowerVPN", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(false); // Отключаем автоматическое завершение при закрытии

  // Получаем HWND для трея и устанавливаем кастомный WndProc
  HWND hwnd = window.GetHandle();
  LONG_PTR style = GetWindowLongPtr(hwnd, GWL_STYLE);
  style &= ~(WS_MAXIMIZEBOX | WS_SIZEBOX); // Убираем возможность максимализации и изменения размера
  SetWindowLongPtr(hwnd, GWL_STYLE, style);
  SetWindowPos(hwnd, nullptr, 0, 0, 360, 640, SWP_NOMOVE | SWP_NOZORDER | SWP_FRAMECHANGED);

  SetWindowLongPtr(hwnd, GWLP_WNDPROC, (LONG_PTR)WndProc);

  CreateTrayIcon(hwnd);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}