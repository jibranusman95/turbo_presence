# Changelog

## [0.1.2] — 2026-06-08

### Fixed
- Railtie asset initializer used `root` which is only available on `Rails::Engine`, not `Rails::Railtie`. Replaced with `Pathname.new(__dir__).join("../..")` to correctly resolve the gem root and add `app/javascript` to the asset load path.

## [0.1.1] — 2026-06-08

### Fixed
- `turbo_presence_for` view helper now sets `room_token` and `identity` as proper Stimulus values (with `-value` suffix). In 0.1.0, these were set as plain data attributes (`data-turbo-presence-room-token` / `data-turbo-presence-identity`), which Stimulus never read — causing the channel subscription to silently fail with `undefined` room token and identity.
- `turbo_presence_for` now correctly forwards a block to the wrapping `div`, allowing content to be rendered inside the presence container.

### Added
- Full spec coverage for `TurboPresence::ViewHelper` (was previously untested and excluded from coverage).

## [0.1.0] — 2026-06-02

### Added
- Initial release: `turbo_presence_for` view helper, Action Cable channel, Redis/memory presence store, Stimulus controller (cursors, avatar stack, typing indicator), RSpec test helpers.
