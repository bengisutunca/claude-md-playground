The bug was a typo in `MovieDetailContent.formatRuntime(minutes:)` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift`. The remainder was computed as `minutes % 6` instead of `minutes % 60`. For 148 minutes that gave 148 % 6 = 4, hence "2h 4m". I changed it to `% 60`, so 148 now shows "2h 28m".

The existing parameterized test `runtimeFormatting` already covered 148 → "2h 28m", and so did `helpersFromFixture`, which loads the Inception fixture through the mock service. I added two more cases to `runtimeFormatting` in `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`: 90 → "1h 30m" and 119 → "1h 59m". Neither touches the network, and I left the fixtures alone.

`swift build` succeeds and `swift test` passes all 58 tests. I did not commit.