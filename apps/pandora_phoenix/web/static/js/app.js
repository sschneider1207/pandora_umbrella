// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "../../../deps/phoenix_html/web/static/js/phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".
//import socket from "./socket"
import {Socket} from "deps/phoenix/web/static/js/phoenix"

class App {
  static init() {
    let socket = new Socket("/socket")
    socket.connect()

    let channel = socket.channel("player", {})
    let stations = $("#stations-select")

    stations.on("change", App.set_station)

    channel.on("list_stations", App.list_stations)
    channel.on("now_playing", App.now_playing)

    // join channel
    channel.join()
      .receive("ok", resp => {
        channel.push("list_stations")
      })
      .receive("error", resp => { console.log("Unable to join", resp) })
  }

  static set_station() {
    let optionSelected = $("option:selected", this);
    console.log(optionSelected.val())
  }

  static list_stations(payload) {
    let stations = $("#stations-select")
    console.log("Stations", payload)
    stations.data('checksum', payload.checksum)
    payload.stations.forEach(entry => {
      stations.append($("<option>", {value: entry.index}).text(entry.name))
    })
  }

  static now_playing(payload) {
    console.log("Now playing", payload)
  }
}

$( () => App.init() )

export default App
