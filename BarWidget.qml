import QtQuick
import Quickshell
import qs.Ui
import "Hijri.js" as Hijri

// Bar label + host for the Hijri calendar popup.
BarWidget {
  id: root
  moduleName: "jp.hijri"

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }
  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }
  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }
  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.settings = root.settings
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Persisted settings (filled by the shell from the stored entry, and
  // updated through the panel via updateEntryInline).
  property var settings: ({})

  onBarChanged: injectPanel()
  onSettingsChanged: {
    if (panelLoader.item) panelLoader.item.settings = root.settings
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  function label() {
    var lang = root.settings.language || "id"
    var off = root.settings.offset || 0
    var d = new Date(clock.date.getTime() + off * 86400000)
    var t = Hijri.hijriFromDate(d)
    var names = lang === "en" ? Hijri.MONTHS_SHORT_EN : Hijri.MONTHS_SHORT_ID
    return t.d + " " + names[t.m - 1] + " " + t.y + " H"
  }

  property string displayLabel: root.label()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.displayLabel
    tooltipText: "Kalender Hijriyah"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }
}
