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

    // вручную — сначала баннер «душа сохранена», потом замок; по простою — сразу
    function lock() {
        if (sessionLock.locked || delayed.running) return;
        if (Banner.enabled()) { Banner.show("ДУША СОХРАНЕНА", Theme.scarlet); delayed.restart(); }
        else lockNow();
    }
    function lockNow() { delayed.stop(); message = ""; sessionLock.locked = true; Sfx.play("lock"); }
    function unlock() {
        if (!sessionLock.locked) return;
        sessionLock.locked = false;
        Banner.show("ВОЗВРАЩЕНИЕ", Theme.text);
    }
    Timer { id: delayed; interval: 1300; onTriggered: root.lockNow() }

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
        timeout: Math.max(1, Store.data.lockMinutes) * 60
        enabled: Store.data.lockMinutes > 0
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lockNow()
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
