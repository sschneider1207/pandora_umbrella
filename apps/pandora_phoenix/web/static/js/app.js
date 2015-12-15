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
    let socket = new Socket("/socket", {
      logger: ((kind, msg, data) => {console.log(`${kind}: ${msg}`, data) })
    })

    socket.connect()
    var $stations = $("#stations-select")
    var $player = $("#player")
    var $audioHigh = $("#audio-high")
    var $audioMed = $("#audio-med")
    var $audioLow = $("#audio-low")

    socket.onOpen( ev => console.log("OPEN", ev) )
    socket.onError( ev => console.log("ERROR", ev) )
    socket.onClose( e => console.log("CLOSE", e))

    var chan = socket.channel("player", {})
    chan.join().receive("ok", () => { console.log("join ok"); chan.push("list_stations"); })
               .after(10000, () => console.log("Connection interruption"))
    chan.onError(e => console.log("something went wrong", e))
    chan.onClose(e => console.log("channel closed", e))

    // update station list and checksum
    chan.on("list_stations", msg => {
      $stations.data('checksum', msg.checksum)
      msg.stations.forEach(entry => {
        $stations.append($("<option>", {value: entry.index}).text(entry.name))
      })
    })

    // set current playing song audio urls
    chan.on("now_playing", msg => {
      var nowPlaying = msg.now_playing
      $audioHigh.attr("src", nowPlaying.urls.highQuality.audioUrl)
      $audioMed.attr("src", nowPlaying.urls.mediumQuality.audioUrl)
      $audioLow.attr("src", nowPlaying.urls.lowQuality.audioUrl)

      $player[0].pause()
      $player[0].load()
      $player[0].oncanplaythrough = $player[0].play()
    })
    
    // set station on select change
    $stations.on("change", event => {
      var $optionSelected = $(event.currentTarget).find("option:selected");
      console.log("option selected", $optionSelected)
      chan.push("set_station", {index: $optionSelected.val()})
    })
  }
}

$( () => App.init() )

export default App
