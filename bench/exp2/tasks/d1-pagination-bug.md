Bug report: on the Popular tab, scrolling to the bottom never loads more movies. Only the first page is ever shown. Find the cause, fix it, and add a regression test.


Constraints:
- Keep the fix minimal and in the layer where the bug is.
- Tests use Swift Testing (`import Testing`); they must never hit the real network.
- Do not commit; do not modify files under `Tests/TMDBAppTests/Fixtures/`.
- When done, run `swift build` and `swift test`. All tests must pass.
