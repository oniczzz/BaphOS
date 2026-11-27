// BaphOS: блокировка сессии (ext-session-lock) с проверкой пароля через PAM.
// Блокируют: IPC lock.lock (Super+Alt+L) и простой 10 минут. Аварийно снять из своего же
// пользователя (например по SSH): qs -c baphos ipc call lock unlock
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: root
    property string message: ""
    property bool busy: false
    property string pending: ""

    function lock() { message = ""; sessionLock.locked = true; Sfx.play("lock"); }
    function unlock() { sessionLock.locked = false }

    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            LockScreen {
                id: view
                anchors.fill: parent
                message: root.message
                busy: root.busy
                onSubmit: pw => {
                    root.pending = pw;
                    root.busy = true;
                    root.message = "";
                    pam.start();
                }
                Component.onCompleted: focusInput()
            }
        }
    }

    PamContext {
        id: pam
        config: "login"
        onPamMessage: {
            if (responseRequired) respond(root.pending);
        }
        onCompleted: result => {
            root.busy = false;
            root.pending = "";
            if (result === PamResult.Success) root.unlock();
            else root.message = "Неверно. Тьма не открывается.";
        }
    }

    // автоблокировка после 10 минут простоя
    IdleMonitor {
        timeout: 600
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lock()
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock() }
        function unlock(): void { root.unlock() }
        function preview(): void { previewWin.visible = !previewWin.visible }
    }

    // превью вида блокировки в обычном окне — без настоящей блокировки
    FloatingWindow {
        id: previewWin
        visible: false
        title: "BaphOS — превью блокировки"
        implicitWidth: 960; implicitHeight: 540
        LockScreen { anchors.fill: parent; message: "так выглядит ошибка пароля" }
    }
}
