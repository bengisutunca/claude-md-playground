I fixed the bug: 148 minutes now shows as "2h 28m". `swift build` succeeds and all 58 tests pass.

The cause was a typo in `MovieDetailContent.formatRuntime` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift`. It computed the leftover minutes as `minutes % 6` instead of `minutes % 60`, so 148 gave 4 and the screen showed "2h 4m". The fix is that one character.

I didn't add a new test, because `MovieDetailViewModelTests.swift` already covers this. `runtimeFormatting` checks `formatRuntime` for 148 → "2h 28m" and 61 → "1h 1m", and `helpersFromFixture` checks `runtimeText` against the Inception fixture. I didn't run the suite before the fix, so I haven't seen those tests fail on the bug. They use a mock service, so nothing touches the network.

I made no commit and didn't touch `Tests/TMDBAppTests/Fixtures/`.