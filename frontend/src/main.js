import { createApp } from "vue"
import PreviewMock from "./PreviewMock.vue"

import "@ionic/vue/css/core.css"
import "./theme/variables.css"
import "./main.css"

window.frappe = {
	boot: {
		lang: "en",
		layout_direction: "ltr",
	},
}

document.documentElement.lang = "en"
document.documentElement.dir = "ltr"

createApp(PreviewMock).mount("#app")
