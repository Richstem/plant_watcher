// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/plant_watcher"
import topbar from "../vendor/topbar"

let customHooks = {}

customHooks.LineChart = {
  mounted() {
    const ctx = this.el.getContext("2d")
    
    this.chart = new window.Chart(ctx, {
      type: "line",
      data: { 
        labels: [], 
        datasets: [          
          { label: "Soil Temp (F)", data: [], borderColor: "#fbbf24", tension: 0.3, yAxisID: 'y', pointRadius: 0, pointHoverRadius: 8  },
          { label: "Moisture", data: [], borderColor: "#60a5fa", tension: 0.3, yAxisID: 'y1', pointRadius: 0, pointHoverRadius: 8 },
          { label: "Device Temp (F)", data: [], borderColor: "#f87171", tension: 0.3, yAxisID: 'y', pointRadius: 0, pointHoverRadius: 8 },
        ]
      },
      options: { 
        plugins: {title: {display: true, text: 'Last 6 Hours', font: {size: 24}}},
        responsive: true, 
        maintainAspectRatio: false,
        scales: {
          y: { 
            type: 'linear', 
            display: true, 
            position: 'left',
            title: {display: true, text: 'Temperature (°F)'},
            suggestedMin: 25, 
            suggestedMax: 110
          },
          y1: { 
            type: 'linear', 
            display: true, 
            position: 'right', 
            title: {display: true, text: "Soil Moisture"},
            grid: { drawOnChartArea: false },
            suggestedMin: 150,
            suggestedMax: 1200
          }
        } 
      }
    })

    this.handleEvent("load_history", ({ data }) => {
      // FIX: Clean up raw database strings so the browser sorts them in exact timeline order
      this.chart.data.labels = data.map(d => {
        if (!d.time) return ""
        // Converts "YYYY-MM-DD HH:MM:SS" to "YYYY-MM-DDTHH:MM:SSZ"
        const cleanIso = d.time.replace(" ", "T")
        return new Date(cleanIso).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })
      })
            
      this.chart.data.datasets[0].data = data.map(d => d.soil_temp)
      this.chart.data.datasets[1].data = data.map(d => d.soil_moisture)
      this.chart.data.datasets[2].data = data.map(d => d.device_temp)
      this.chart.update()
    })
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ...customHooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

