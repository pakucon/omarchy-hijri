import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Hijri.js" as Hijri

// One-month Hijri calendar popup, styled after the omarchy.clock calendar:
// a large hero date, a progress rail, a 6x7 day grid with today outlined,
// and month stepping via chevrons, arrow keys, or the scroll wheel.
Panel {
  id: root
  moduleName: "jp.hijri"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  function effectiveDate(base) {
    return new Date(base.getTime() + root.offset * 86400000);
  }

  property var today: effectiveDate(new Date())
  readonly property var todayH: Hijri.hijriFromDate(today)

  property int viewYear: todayH.y
  property int viewMonth: todayH.m

  readonly property bool viewingCurrentMonth: viewYear === todayH.y && viewMonth === todayH.m

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property int cellWidth: Style.space(60)
  readonly property int cellHeight: Style.space(40)
  readonly property int cellSpacing: Style.space(2)

  // ---- Localization.
  readonly property var weekdays: ({
    id: ["SEN", "SEL", "RAB", "KAM", "JUM", "SAB", "MIN"],
    en: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
  })
  readonly property var months: ({
    id: ["Muharram", "Safar", "Rabiul Awal", "Rabiul Akhir", "Jumadil Awal", "Jumadil Akhir", "Rajab", "Sya'ban", "Ramadhan", "Syawal", "Dzulqa'dah", "Dzulhijjah"],
    en: ["Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani", "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban", "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"]
  })
  readonly property var labels: ({
    id: { language: "Bahasa", indonesia: "Indonesia", inggris: "Inggris", dateAdj: "Penyesuaian tanggal", days: "hari", settings: "Pengaturan" },
    en: { language: "Language", indonesia: "Indonesian", inggris: "English", dateAdj: "Date adjustment", days: "days", settings: "Settings" }
  })

  // ---- Persisted settings (saved into the widget entry via updateEntryInline).
  property var settings: ({})
  property string language: setting("language", "id")
  property int offset: setting("offset", 0)

  readonly property var weekdayLabels: root.weekdays[root.language]

  property bool showSettings: false

  // 42 cells (6 rows x 7 columns), each { day, today }.
  property var cells: []

  function rebuild() {
    var lead = Hijri.dayOfWeek(viewYear, viewMonth, 1); // 0 = Monday
    var len = Hijri.monthLength(viewYear, viewMonth);
    var arr = [];
    for (var i = 0; i < lead; i++) arr.push({ day: -1, today: false });
    for (var d = 1; d <= len; d++) {
      var isToday = (d === todayH.d && viewMonth === todayH.m && viewYear === todayH.y);
      arr.push({ day: d, today: isToday });
    }
    while (arr.length < 42) arr.push({ day: -1, today: false });
    root.cells = arr;
  }

  function open() {
    root.refresh();
    root.controller.show();
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true);
    });
  }
  function close() {
    setCenterHoverRevealSuppressed(false);
    root.controller.hide();
  }
  function toggle() {
    if (root.opened) root.close();
    else root.open();
  }
  function closeForPopoutSwitch() {
    root.controller.hide();
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction);
    return false;
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value;
  }

  function refresh() {
    root.today = new Date();
    root.goToToday();
  }
  function goToToday() {
    root.viewYear = todayH.y;
    root.viewMonth = todayH.m;
  }
  function moveMonth(delta) {
    var next = Hijri.stepMonth(viewYear, viewMonth, delta);
    root.viewYear = next.year;
    root.viewMonth = next.month;
  }
  function moveYear(delta) {
    var next = Hijri.stepMonth(viewYear, viewMonth, 12 * delta);
    root.viewYear = next.year;
    root.viewMonth = next.month;
  }

  Component.onCompleted: rebuild()

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: {
      var h = Hijri.hijriFromDate(root.effectiveDate(clock.date));
      if (h.y === todayH.y && h.m === todayH.m && h.d === todayH.d) return;
      var follow = root.viewingCurrentMonth;
      root.today = root.effectiveDate(clock.date);
      if (follow) root.goToToday();
    }
  }

  onViewYearChanged: rebuild()
  onViewMonthChanged: rebuild()
  onTodayHChanged: rebuild()
  onOffsetChanged: root.today = root.effectiveDate(clock.date)
  onLanguageChanged: rebuild()

  Binding {
    target: root
    property: "showSettings"
    value: false
    when: !root.open
  }

  function setLanguage(lang) {
    root.language = lang;
    root.persistSettings({});
  }
  function changeOffset(delta) {
    var v = Math.max(-3, Math.min(3, root.offset + delta));
    root.offset = v;
    root.persistSettings({});
  }
  function persistSettings(values) {
    var entry = { id: root.moduleName };
    entry["language"] = root.language;
    entry["offset"] = root.offset;
    for (var k in values) entry[k] = values[k];
    root.settings = entry;
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry);
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(gridColumn.implicitWidth + Style.space(40))
    contentHeight: panel.fittedContentHeight(calendarColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.moveMonth(dx);
        if (dy !== 0) root.moveYear(dy);
      }
      onActivateRequested: root.goToToday()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "[") root.moveMonth(-1);
        else if (t === "]") root.moveMonth(1);
        else if (t === "{") root.moveYear(-1);
        else if (t === "}") root.moveYear(1);
        else if (t === "t" || t === "T") root.goToToday();
      }

      Flickable {
        id: calendarScroll
        anchors.fill: parent
        contentWidth: calendarColumn.width
        contentHeight: calendarColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height || contentWidth > width

        Column {
          id: calendarColumn
          width: Math.max(calendarScroll.width, gridColumn.width)
          spacing: Style.space(8)

          // ---- Hero: today, centered. Clicking it returns to the current
          //      month once the view has been stepped away.
          Item {
            width: parent.width
            height: heroRow.height

            Row {
              id: heroRow
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(22)

              Text {
                anchors.baseline: heroDate.baseline
                text: "󰃭"
                color: heroMouse.containsMouse
                  ? Style.hoverStateColor(root.contentForeground, Color.accent)
                  : root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: 32
              }

              Text {
                id: heroDate
                text: root.todayH.d + " " + root.months[root.language][root.todayH.m - 1]
                color: heroMouse.containsMouse
                  ? Style.hoverStateColor(root.contentForeground, Color.accent)
                  : root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: 38
                font.bold: true
              }
            }

            MouseArea {
              id: heroMouse
              x: heroRow.x
              y: heroRow.y
              width: heroRow.width
              height: heroRow.height
              enabled: !root.viewingCurrentMonth
              hoverEnabled: enabled
              cursorShape: Qt.PointingHandCursor
              onClicked: root.goToToday()

              PanelToolTip {
                visible: heroMouse.containsMouse
                text: "Kembali ke hari ini"
                fontFamily: root.contentFontFamily
              }
            }
          }

          // ---- Month grid: weekday header, then the 6x7 day grid.
          Item {
            width: parent.width
            height: gridColumn.y + gridColumn.height

            WheelHandler {
              onWheel: function(event) {
                if (event.angleDelta.y === 0) return;
                root.moveMonth(event.angleDelta.y > 0 ? -1 : 1);
              }
            }

            Column {
              id: gridColumn
              y: Style.space(18)
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(3)

              Row {
                id: headerRow
                spacing: root.cellSpacing

                Repeater {
                  model: root.weekdayLabels

                  Text {
                    required property var modelData
                    width: root.cellWidth
                    height: Style.space(16)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: Qt.darker(root.contentForeground, 1.5)
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    font.letterSpacing: 1
                    font.bold: true
                  }
                }
              }

              Grid {
                id: dayGrid
                columns: 7
                spacing: root.cellSpacing
                width: implicitWidth

                Repeater {
                  model: root.cells

                  Rectangle {
                    required property var modelData
                    width: root.cellWidth
                    height: root.cellHeight
                    radius: Style.cornerRadius
                    color: "transparent"
                    border.width: modelData.today ? Style.spacing.hairline : 0
                    border.color: Style.normalBorderFor(root.contentForeground, Color.accent)

                    Text {
                      anchors.centerIn: parent
                      text: modelData.day >= 0 ? modelData.day : ""
                      color: root.contentForeground
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.body
                      font.bold: modelData.today
                    }
                  }
                }
              }
            }
          }

          // ---- Month stepping, spanning the grid it drives.
          Item {
            width: parent.width
            height: monthNav.height

            Item {
              id: monthNav
              anchors.horizontalCenter: parent.horizontalCenter
              width: gridColumn.width
              height: monthLabel.implicitHeight + Style.space(10)

              Text {
                id: monthLabel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: gridColumn.width
                horizontalAlignment: Text.AlignHCenter
                text: root.months[root.language][root.viewMonth - 1].toUpperCase() + " " + root.viewYear + " H"
                color: Qt.darker(root.contentForeground, 1.4)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.letterSpacing: 1
              }

              PanelActionButton {
                anchors.left: parent.left
                anchors.leftMargin: -Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                iconText: "󰅁"
                tooltipText: "Bulan sebelumnya"
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.moveMonth(-1)
              }
              PanelActionButton {
                anchors.right: parent.right
                anchors.rightMargin: -Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                iconText: "󰅂"
                tooltipText: "Bulan berikutnya"
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.moveMonth(1)
              }
            }
          }

          // ---- Settings toggle, below the month selector.
          Item {
            width: parent.width
            height: Style.space(22)

            PanelActionButton {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              iconText: "󰒓"
              tooltipText: root.labels[root.language].settings
              foreground: root.showSettings ? Color.accent : root.contentForeground
              fontFamily: root.contentFontFamily
              onClicked: root.showSettings = !root.showSettings
            }
          }

          // ---- Settings (expands the popup downward).
          Item {
            visible: root.showSettings
            width: parent.width
            height: settingsColumn.height + Style.space(6)

            Column {
              id: settingsColumn
              y: Style.space(6)
              width: parent.width
              spacing: Style.space(12)

              PanelSeparator { width: parent.width }

              Row {
                width: parent.width
                spacing: Style.space(10)

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.labels[root.language].language
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Item { width: Style.space(8); height: 1 }

                PanelActionButton {
                  anchors.verticalCenter: parent.verticalCenter
                  iconText: "ID"
                  tooltipText: root.labels[root.language].indonesia
                  foreground: root.language === "id" ? Color.accent : root.contentForeground
                  fontFamily: root.contentFontFamily
                  onClicked: root.setLanguage("id")
                }

                PanelActionButton {
                  anchors.verticalCenter: parent.verticalCenter
                  iconText: "EN"
                  tooltipText: root.labels[root.language].inggris
                  foreground: root.language === "en" ? Color.accent : root.contentForeground
                  fontFamily: root.contentFontFamily
                  onClicked: root.setLanguage("en")
                }
              }

              Row {
                width: parent.width
                spacing: Style.space(10)

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.labels[root.language].dateAdj
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Item { width: Style.space(8); height: 1 }

                PanelActionButton {
                  anchors.verticalCenter: parent.verticalCenter
                  iconText: "-"
                  tooltipText: "-1"
                  foreground: root.contentForeground
                  fontFamily: root.contentFontFamily
                  onClicked: root.changeOffset(-1)
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  width: Style.space(72)
                  horizontalAlignment: Text.AlignHCenter
                  text: (root.offset > 0 ? "+" : "") + root.offset + " " + root.labels[root.language].days
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                }

                PanelActionButton {
                  anchors.verticalCenter: parent.verticalCenter
                  iconText: "+"
                  tooltipText: "+1"
                  foreground: root.contentForeground
                  fontFamily: root.contentFontFamily
                  onClicked: root.changeOffset(1)
                }
              }
            }
          }

        }
      }
    }
  }
}
