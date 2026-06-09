# turbo_presence

**Figma-style live cursors, avatar stacks, and typing indicators for Rails. One line.**

[![CI](https://github.com/jibranusman95/turbo_presence/actions/workflows/ci.yml/badge.svg)](https://github.com/jibranusman95/turbo_presence/actions)
[![Gem Version](https://badge.fury.io/rb/turbo_presence.svg)](https://badge.fury.io/rb/turbo_presence)
[![Downloads](https://img.shields.io/gem/dt/turbo_presence)](https://rubygems.org/gems/turbo_presence)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

> **[GIF: two browser windows side by side — cursor moves on the left, appears instantly on the right. User starts typing, "Alice is typing…" appears. Second user joins, avatar appears in stack. First user leaves, avatar disappears. 8 seconds. No words needed.]**

---

Your users are already in the same document at the same time. They just can't see each other.

Liveblocks costs $200/month and requires you to rewrite your frontend in JavaScript. Phoenix has presence built in. Rails has nothing.

Until now.

```erb
<%# That's it. Cursors, avatars, typing indicators. Done. %>
<%= turbo_presence_for(@document) %>
```

No JavaScript to write. No third-party service. No monthly bill. Built on Action Cable — the thing already in your Rails app.

---

## What you get

**Live cursors** — every user's mouse position, in real time, element-relative so it works on every screen size.

**Avatar stack** — see who's viewing the same record right now. Updates instantly when someone joins or leaves.

**Typing indicators** — "Alice is typing…" fires when a user is active, clears automatically when they stop.

**Zero config for Devise users** — one initializer line and you're done.

---

## Install

```ruby
# Gemfile
gem "turbo_presence"
```

```bash
bundle install
rails turbo_presence:install
```

```ruby
# config/initializers/turbo_presence.rb
TurboPresence.configure do |config|
  config.identify_user { |user| { id: user.id, name: user.name } }
end
```

```erb
<%# app/views/documents/show.html.erb %>
<%= turbo_presence_for(@document) %>

<%= form_with model: @document do |f| %>
  <%= f.text_area :content %>
<% end %>
```

That's the entire integration. Ship it.

---

## How it looks

```
┌──────────────────────────────────────────────────────┐
│  📄 Quarterly Report                                 │
│                                                      │
│  👤 Alice  👤 Bob  +2        ← avatar stack         │
│  Alice is typing…            ← typing indicator      │
│                                                      │
│  The Q3 numbers show▌                                │
│            ↖ Bob             ← live cursor           │
└──────────────────────────────────────────────────────┘
```

---

## Full API

### View helper

```erb
<%# Basic — cursors + avatars + typing %>
<%= turbo_presence_for(@document) %>

<%# Custom container %>
<%= turbo_presence_for(@document, class: "my-presence-bar") %>

<%# Disable specific features %>
<%= turbo_presence_for(@document, cursors: false, typing: false) %>
```

### Configuration

```ruby
TurboPresence.configure do |config|
  # Required — return a hash identifying the current user
  config.identify_user do |user|
    {
      id:     user.id,
      name:   user.display_name,
      avatar: user.avatar_url,   # optional
      color:  user.presence_color # optional — auto-assigned if omitted
    }
  end

  # Optional — Redis URL (auto-detected from ENV["REDIS_URL"] if present)
  config.redis_url = "redis://localhost:6379/1"

  # Optional — how long before a stale presence entry expires (default: 60s)
  config.presence_ttl = 60

  # Optional — cursor throttle in milliseconds (default: 50ms)
  config.cursor_throttle_ms = 50
end
```

### JavaScript hooks (optional)

```javascript
// Listen to presence events in your own JS if needed
document.addEventListener("turbo-presence:join", (e) => {
  console.log(`${e.detail.name} joined`)
})

document.addEventListener("turbo-presence:leave", (e) => {
  console.log(`${e.detail.name} left`)
})

document.addEventListener("turbo-presence:cursor", (e) => {
  console.log(`${e.detail.name} moved to`, e.detail.x, e.detail.y)
})
```

---

## Why not just use Liveblocks / PartyKit / WebSockets directly?

| | turbo_presence | Liveblocks | PartyKit | Roll your own |
|---|---|---|---|---|
| **Cost** | Free | $25–$200/mo | Pay per connection | Free |
| **Rails-native** | ✓ | ✗ | ✗ | ✓ |
| **Zero JS** | ✓ | ✗ | ✗ | ✗ |
| **Works with Devise** | ✓ | Manual | Manual | Manual |
| **Action Cable** | ✓ | ✗ | ✗ | ✓ |
| **Setup time** | 5 min | Hours | Hours | Days |
| **Vendor lock-in** | None | High | High | None |

Phoenix LiveView has presence built in. Rails deserves the same.

---

## How it works

`turbo_presence_for(@document)` renders a Stimulus controller mount point scoped to `Document#42` (or whatever record you pass). Under the hood:

1. **Stimulus controller** connects to an Action Cable channel on mount, identified by a signed room token (model class + id)
2. **`mousemove` events** are captured, normalized to element-relative 0.0–1.0 coordinates, throttled to 50ms, and broadcast to all subscribers
3. **Presence store** (Redis-backed, memory fallback) tracks who's in each room with a 60s TTL — stale connections auto-expire
4. **Remote cursors** are rendered as absolutely-positioned DOM elements, coordinates denormalized to the local element bounds
5. **On disconnect** — the channel broadcasts a departure event, the avatar disappears, cursors are removed

Cursor coordinates are normalized (`0.0` to `1.0` relative to the element) so they work identically on a 13" laptop and a 4K monitor.

---

## Real-world examples

<details>
<summary>Collaborative document editor</summary>

```erb
<%# app/views/documents/show.html.erb %>
<div class="document-editor">
  <%= turbo_presence_for(@document) %>

  <%= form_with model: @document, data: { controller: "autosave" } do |f| %>
    <%= f.text_area :content, rows: 30 %>
  <% end %>
</div>
```
</details>

<details>
<summary>Kanban board — per-card presence</summary>

```erb
<%# app/views/cards/_card.html.erb %>
<div class="card">
  <h3><%= card.title %></h3>
  <%= turbo_presence_for(card, cursors: false) %>  <%# avatars only — no cursors on small cards %>
</div>
```
</details>

<details>
<summary>Live dashboard — who's watching</summary>

```erb
<%# app/views/dashboards/show.html.erb %>
<div class="dashboard-header">
  <h1>Sales Dashboard</h1>
  <%= turbo_presence_for(@dashboard, typing: false) %>  <%# cursors + avatars, no typing %>
</div>
```
</details>

<details>
<summary>Custom user identity with colors</summary>

```ruby
# config/initializers/turbo_presence.rb
TurboPresence.configure do |config|
  config.identify_user do |user|
    {
      id:     user.id,
      name:   user.full_name,
      avatar: url_for(user.avatar),
      color:  user.team_color || TurboPresence.auto_color(user.id)
    }
  end
end
```
</details>

---

## System test helpers

```ruby
# spec/support/turbo_presence.rb
require "turbo_presence/test_helpers"

RSpec.describe "document editing", type: :system do
  include TurboPresence::TestHelpers

  it "shows who is viewing the document" do
    using_session(:alice) { visit document_path(@document) }
    using_session(:bob)   { visit document_path(@document) }

    using_session(:alice) do
      expect(page).to have_presence_of("Bob")
    end
  end

  it "shows live cursors" do
    using_session(:alice) { visit document_path(@document) }
    using_session(:bob)   { visit document_path(@document) }

    simulate_cursor(x: 0.5, y: 0.3, as: :alice)

    using_session(:bob) do
      expect(page).to have_cursor_near(x: 0.5, y: 0.3, tolerance: 0.05)
    end
  end

  it "shows typing indicators" do
    using_session(:alice) { visit document_path(@document) }
    using_session(:bob) do
      visit document_path(@document)
      simulate_typing(as: :alice)
      expect(page).to have_text("Alice is typing…")
    end
  end
end
```

---

## Requirements

- Ruby >= 3.1
- Rails >= 7.0
- Action Cable
- Hotwire / Turbo
- Stimulus >= 3.0
- Redis (optional — memory store used as fallback)

---

## Contributing

```bash
git clone https://github.com/jibranusman95/turbo_presence
cd turbo_presence
bundle install
bundle exec rspec
bundle exec rubocop
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.

---

## Further Reading

- [How I built Google Docs cursors in Rails with 1 line](#) *(coming soon)*

---

## From the same author

Small, sharp Ruby gems built to the same standard — 100% test coverage, zero dependencies beyond what's needed.

| Gem | What it does |
|-----|-------------|
| [llm_cassette](https://github.com/jibranusman95/llm_cassette) | VCR for LLMs — streaming-aware cassette recorder for OpenAI and Anthropic |
| [promptscrub](https://github.com/jibranusman95/promptscrub) | PII redaction middleware for LLM calls — strip sensitive data from prompts, rehydrate in responses |
| [http_decoy](https://github.com/jibranusman95/http_decoy) | A real Rack server that runs inside your RSpec tests — test HTTP contracts, not stubs |
| [webhook_inbox](https://github.com/jibranusman95/webhook_inbox) | Transactional inbox for Rails webhook receivers — deduplication, async processing, replay, dashboard |

## License

MIT. See [LICENSE](LICENSE).
