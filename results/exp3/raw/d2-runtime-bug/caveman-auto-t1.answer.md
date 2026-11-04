Fixed. Inception now shows "2h 28m". `swift build` succeeds and `swift test` passes all 58 tests.

**Cause:** `MovieDetailContent.formatRuntime(minutes:)` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24` got the leftover minutes with `minutes % 6` instead of `minutes % 60`. For 148 minutes that gave 148 % 6 = 4, so the screen showed "2h 4m". The hours part was already correct.

**Fix:** I changed `% 6` to `% 60` in that one place. Nothing else changed.

**Regression test:** The test file already had a Swift Testing case for 148 → "2h 28m". I added three more cases to the same test (`runtimeFormatting` in `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`), each of which the old code would have gotten wrong:
- 90 → "1h 30m"
- 119 → "1h 59m"
- 126 → "2h 6m" (the old code showed just "2h", since 126 % 6 = 0)

The tests use the existing mock service, so nothing touches the real network. I didn't modify any fixtures and didn't commit anything.