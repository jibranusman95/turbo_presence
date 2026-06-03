import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = {
    roomToken: String,
    identity:  String,
    cursors:   { type: Boolean, default: true },
    typing:    { type: Boolean, default: true },
    throttle:  { type: Number,  default: 50 }
  }

  connect() {
    this._identity      = JSON.parse(this.identityValue)
    this._typingTimeout = null
    this._lastCursor    = 0
    this._cursors       = {}

    this._channel = createConsumer().subscriptions.create(
      {
        channel:    "TurboPresenceChannel",
        room_token: this.roomTokenValue,
        identity:   this.identityValue
      },
      {
        received: (data) => this._handleMessage(data),
        connected: () => this._startHeartbeat(),
        disconnected: () => this._stopHeartbeat()
      }
    )

    if (this.cursorsValue) {
      this._onMouseMove = this._trackCursor.bind(this)
      this.element.addEventListener("mousemove", this._onMouseMove)
    }

    if (this.typingValue) {
      this._onKeyDown = this._trackTyping.bind(this)
      document.addEventListener("keydown", this._onKeyDown)
    }
  }

  disconnect() {
    this._channel?.unsubscribe()
    this._stopHeartbeat()
    this.element.removeEventListener("mousemove", this._onMouseMove)
    document.removeEventListener("keydown", this._onKeyDown)
    this._removeAllCursors()
  }

  // — Private —

  _handleMessage(data) {
    switch (data.type) {
      case "presence": this._renderAvatars(data.users);              break
      case "cursor":   this._renderCursor(data);                     break
      case "typing":   this._renderTyping(data.name, data.active);   break
    }
  }

  _trackCursor(event) {
    const now = Date.now()
    if (now - this._lastCursor < this.throttleValue) return
    this._lastCursor = now

    const rect = this.element.getBoundingClientRect()
    const x    = ((event.clientX - rect.left) / rect.width).toFixed(4)
    const y    = ((event.clientY - rect.top)  / rect.height).toFixed(4)

    this._channel.perform("cursor", { x: parseFloat(x), y: parseFloat(y) })
  }

  _trackTyping() {
    this._channel.perform("typing", { active: true })
    clearTimeout(this._typingTimeout)
    this._typingTimeout = setTimeout(() => {
      this._channel.perform("typing", { active: false })
    }, 2000)
  }

  _renderAvatars(users) {
    let container = this.element.querySelector("[data-turbo-presence='avatars']")
    if (!container) {
      container = document.createElement("div")
      container.dataset.turboPresence = "avatars"
      container.className = "turbo-presence-avatars"
      this.element.prepend(container)
    }

    const others = users.filter(u => String(u.id) !== String(this._identity.id))
    const visible = others.slice(0, 5)
    const overflow = others.length - visible.length

    container.innerHTML = visible.map(u => `
      <div class="turbo-presence-avatar" style="background:${u.color || "#607D8B"}" title="${this._esc(u.name)}">
        ${u.avatar ? `<img src="${this._esc(u.avatar)}" alt="${this._esc(u.name)}" />` : this._initials(u.name)}
      </div>
    `).join("") + (overflow > 0 ? `<div class="turbo-presence-avatar turbo-presence-overflow">+${overflow}</div>` : "")

    this.element.dispatchEvent(new CustomEvent("turbo-presence:join", { detail: { users }, bubbles: true }))
  }

  _renderCursor(data) {
    if (String(data.user_id) === String(this._identity.id)) return

    let cursor = this._cursors[data.user_id]
    if (!cursor) {
      cursor = document.createElement("div")
      cursor.className = "turbo-presence-cursor"
      this.element.appendChild(cursor)
      this._cursors[data.user_id] = cursor
    }

    const rect = this.element.getBoundingClientRect()
    cursor.style.left = `${(data.x * rect.width).toFixed(1)}px`
    cursor.style.top  = `${(data.y * rect.height).toFixed(1)}px`
    cursor.innerHTML  = `<svg viewBox="0 0 16 16" width="16" height="16"><path d="M0 0l4 16 3-5 5 3L0 0z" fill="${data.color || "#607D8B"}"/></svg><span>${this._esc(data.name || "")}</span>`

    this.element.dispatchEvent(new CustomEvent("turbo-presence:cursor", { detail: data, bubbles: true }))
  }

  _renderTyping(name, active) {
    let indicator = this.element.querySelector("[data-turbo-presence='typing']")
    if (!indicator) {
      indicator = document.createElement("div")
      indicator.dataset.turboPresence = "typing"
      indicator.className = "turbo-presence-typing"
      this.element.appendChild(indicator)
    }
    indicator.textContent = active ? `${name} is typing\u2026` : ""
    indicator.hidden = !active
  }

  _removeAllCursors() {
    Object.values(this._cursors).forEach(el => el.remove())
    this._cursors = {}
  }

  _startHeartbeat() {
    this._heartbeat = setInterval(() => this._channel.perform("heartbeat"), 30000)
  }

  _stopHeartbeat() {
    clearInterval(this._heartbeat)
  }

  _initials(name) {
    return (name || "?").split(" ").map(w => w[0]).slice(0, 2).join("").toUpperCase()
  }

  _esc(str) {
    return String(str).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]))
  }
}
