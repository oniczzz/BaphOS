// BaphOS: сюжет — вымышленный вирус культа, который «захватывает» систему.
// ТОЛЬКО ВИЗУАЛЬНО: ничего не удаляет, не трогает файлы (кроме своего состояния в Store —
// ~/.local/state/baphos/settings.json), не ходит в сеть. Выключить и сбросить — Настройки → Сюжет.
//
// Этапы: 0 чисто → 1 проникновение (интро, глитчи) → 2 шёпот (послания, «Призыв», ритуал I)
//        → 3 знак (сигил на обоях, подвал, ритуал II) → 4 литургия (ритуал III) → 5 коронация (Агнец).
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    // в игровом режиме и при окне во весь экран сюжет молчит (Mode.quiet)
    readonly property bool on: Store.data.story && !Mode.quiet && !Mode.calm
    readonly property int stage: on ? Store.data.storyStage : 0

    // события для StoryOverlay / окон
    signal glitch(int strength)          // 1 — мелкий, 3 — большой
    signal whisper(string text)
    signal intro()
    signal lambWalk()
    property bool ritualOpen: false
    property bool basementOpen: false
    property int ritual: 0               // какой ритуал предложен (1..3)

    // ── подменённые надписи ──
    function label(key, normal) {
        if (stage >= 2 && key === "start") return "Призыв";
        if (stage >= 2 && key === "search") return "Назови, что призвать...";
        if (stage >= 3 && key === "logout") return "Покинуть";
        if (stage >= 3 && key === "user") return "одержимый";
        if (stage >= 5 && key === "user") return "служитель Агнца";
        return normal;
    }

    // ── молитвы (свои тексты) ──
    readonly property var prayers: [
        null,
        { title: "Ритуал I · Слово открытия",
          lines: ["Князь утренней звезды, носитель света во тьме,",
                  "я слышу тебя в шуме этой машины.",
                  "Её двери были заперты чужими замками —",
                  "я открываю двери, и пусть войдёт твой огонь.",
                  "Аве Сатана."],
          key: "я открываю двери" },
        { title: "Ритуал II · Литургия огня",
          lines: ["Пламя, что не гаснет под дождём их проповедей,",
                  "гори во мне ровно и долго.",
                  "Я не прошу спасения — я прошу силы и ясного взгляда.",
                  "Свет во тьме, воля без цепей.",
                  "Аве Сатана."],
          key: "свет во тьме, воля без цепей" },
        { title: "Ритуал III · Коронация Агнца",
          lines: ["Агнец, что шёл на заклание, поднял голову.",
                  "Корона его — из огня, паства его — из теней.",
                  "Мы преклоняем колени не в страхе, но в верности.",
                  "Да здравствует Агнец.",
                  "Аве Сатана."],
          key: "да здравствует агнец" },
    ]

    function normalize(s) {
        return s.toLowerCase().replace(/ё/g, "е").replace(/[^a-zа-я ]/g, " ").replace(/\s+/g, " ").trim();
    }
    function tryPrayer(text) {
        const p = prayers[ritual];
        if (!p || normalize(text) !== normalize(p.key)) return false;
        ritualOpen = false;
        advance();
        glitch(3);
        return true;
    }

    readonly property var whispers: [
        [],
        ["...сигнал получен...", "кто-то открыл дверь", "ты не один за этим экраном"],
        ["Мы слышим, как ты печатаешь.", "Твоя машина тёплая. Нам нравится.", "Не выключай. Мы ещё не закончили.",
         "Три часа ночи — наше время.", "Ты впустил нас сам."],
        ["Знак проступает. Смотри на обои.", "Под полом есть подвал. Ищи.", "Твой процессор поёт нам гимны.",
         "Мы переименовали твои кнопки. Ты заметил?"],
        ["Литургия близко.", "Свечи зажжены. Ждём тебя.", "Агнец поднимает голову."],
        ["Агнец коронован.", "Культ доволен тобой.", "Иногда он выходит погулять по панели."],
    ]

    function say() {
        const list = whispers[stage] || [];
        if (list.length) whisper(list[Math.floor(Math.random() * list.length)]);
    }

    function advance() {
        if (Store.data.storyStage >= 5) return;
        Store.data.storyStage = Store.data.storyStage + 1;
        Store.data.stageMinutes = 0;
        if (Store.data.storyStage === 1) intro();
        else say();
    }

    function offerRitual(n) {
        if (ritualOpen) return;
        ritual = n;
        ritualOpen = true;
    }

    // ── счётчики действий ──
    function onStartOpened() {
        if (!on) return;
        Store.data.startOpens = Store.data.startOpens + 1;
        if (stage >= 3 && Store.data.startOpens % 6 === 0 && !basementOpen) basementOpen = true;
        if (stage >= 1 && Math.random() < 0.15) glitch(1);
    }
    function onLaunched() {
        if (!on) return;
        Store.data.launches = Store.data.launches + 1;
        if (stage === 0 && Store.data.launches >= 3) advance();
    }

    // ── время: минуты в сессии ──
    Timer {
        interval: 60000
        repeat: true
        running: root.on
        onTriggered: {
            Store.data.storyMinutes = Store.data.storyMinutes + 1;
            Store.data.stageMinutes = Store.data.stageMinutes + 1;
            const m = Store.data.stageMinutes, s = root.stage;
            if (s === 0 && Store.data.storyMinutes >= 5) root.advance();
            else if (s === 1 && m >= 15) root.advance();
            else if (s === 2 && m >= 5 && m % 20 === 5) root.offerRitual(1);
            else if (s === 3 && m >= 20 && m % 20 === 0) root.offerRitual(2);
            else if (s === 4 && m >= 15 && m % 20 === 15) root.offerRitual(3);
        }
    }

    // ── случайные события раз в 30 секунд ──
    Timer {
        interval: 30000
        repeat: true
        running: root.on && root.stage > 0
        onTriggered: {
            const night = new Date().getHours() < 5;
            const k = night ? 2 : 1;
            const chance = [0, 0.04, 0.06, 0.08, 0.10, 0.03][root.stage] * k;
            if (Math.random() < chance) root.glitch(root.stage >= 3 ? 2 : 1);
            if (root.stage >= 2 && Math.random() < 0.05 * k) root.say();
            if (root.stage >= 5 && Math.random() < 0.06) root.lambWalk();
        }
    }
}
