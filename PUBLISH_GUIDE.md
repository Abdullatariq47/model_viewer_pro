# 🚀 How to Publish `model_viewer_pro` to pub.dev

This guide provides step-by-step instructions for verifying, publishing, and updating your `model_viewer_pro` package on [pub.dev](https://pub.dev). Follow this carefully to ensure a perfect 140/140 Pub Points score.

---

## 0. Initial Setup & GitHub Sync

A fresh local Git repository has already been initialized for you and linked to your remote repository URL. 

To push your local code up to GitHub for the first time, open your terminal in the `model_viewer_pro` folder and run:

```bash
git push -u origin main
```

If you ever need to change your remote repository URL in the future:
```bash
git remote set-url origin https://github.com/Abdullatariq47/model_viewer_pro.git
```

---

## 1. Pre-publish Checklist

### A. Clean the workspace
Ensure you are starting with a clean slate to avoid uploading cached or broken files:
```bash
flutter clean
flutter pub get
```

### B. Verify `pubspec.yaml`
Open `pubspec.yaml` and confirm the following fields before every publish:

| Field | Requirement |
|-------|-------------|
| `name` | Must be `model_viewer_pro` (all lowercase, underscores only) |
| `version` | Bump correctly — `1.0.0`, `1.0.1`, `1.1.0` — using [Semver](https://semver.org) |
| `description` | 60–180 characters, describes the package clearly for pub.dev search |
| `homepage` | Your public GitHub repository URL |
| `repository` | Same GitHub URL (used by pub.dev's "repository" badge) |
| `issue_tracker` | `https://github.com/Abdullatariq47/model_viewer_pro/issues` |

### C. Update `CHANGELOG.md`
Every published version **must** have a changelog entry. Follow this pattern at the top of the file:

```markdown
## [1.0.1] — YYYY-MM-DD

### Added
- Added new feature X.
### Fixed
- Fixed bug with Y.
```

### D. Run the Analyzer
```bash
dart analyze
```
> [!IMPORTANT]
> Fix all warnings and errors before proceeding. Pub.dev will heavily penalize your score if the analyzer fails.

### E. Run the Formatter
```bash
dart format .
```
Pub.dev expects all Dart code to be perfectly formatted according to the official style guide.

---

## 2. Dry-run Verification

Always run a dry-run first. This simulates the upload process and catches errors without actually publishing:

```bash
dart pub publish --dry-run
```

Read the terminal output carefully:
- ✅ `Package has 0 warnings.` — You are ready to publish!
- ⚠️  **Warnings** — Fix these. They will negatively affect your pub.dev score.
- ❌ **Errors** — You cannot publish until these are resolved.

**Common issues and fixes:**

| Warning / Error | Solution |
|---------|-----|
| Missing dartdoc comment on public API | Add `///` comments above classes/methods. |
| Unformatted source files | Run `dart format .` |
| `homepage` not set | Add `homepage:` in `pubspec.yaml` |
| Large files included (e.g. models) | Ensure large `example/assets` are excluded or keep package size small. |

---

## 3. Publish to Pub.dev

Once the dry-run passes with 0 warnings:

```bash
dart pub publish
```

1. Type `y` when prompted to confirm.
2. A browser URL will appear — click it, sign in with your Google account, and click **Allow** to authorize the Pub.dev OAuth flow.
3. The CLI will confirm the successful upload and display your live package URL!

---

## 4. Post-publish Validation

1. Visit `https://pub.dev/packages/model_viewer_pro` within a few minutes.
2. Check your **Pub Points** score on the **Scores** tab. Aim for maximum points.

| Score category | How to achieve |
|----------------|------|
| Follow Dart file conventions | Run `dart format .` |
| Provide documentation | Add `///` comments to all public APIs |
| Pass static analysis | `dart analyze` with zero errors/warnings |
| Support up-to-date dependencies | Keep dependencies in `pubspec.yaml` updated |

---

## 5. Publishing a New Version (Updates)

When you make changes and want to release an update:
1. Make your code changes.
2. Bump the `version` in `pubspec.yaml` following Semantic Versioning:
   - **Patch** (`1.0.0` → `1.0.1`) — Bug fixes only.
   - **Minor** (`1.0.0` → `1.1.0`) — New backwards-compatible features.
   - **Major** (`1.0.0` → `2.0.0`) — Breaking API changes.
3. Add a new section at the top of `CHANGELOG.md`.
4. Run `dart pub publish --dry-run` and fix any issues.
5. Run `dart pub publish`.

---

## 6. Retract a Version (Emergency)

If a published version has a critical bug, you can retract it within 7 days. Note: Retraction is **not** deletion — users who already depend on it will get a warning, but it prevents new users from downloading it.

```bash
dart pub publish retract 1.0.0
```

> [!TIP]
> Always publish a fixed patch version (e.g., `1.0.1`) immediately after retracting a broken version.

---

## 7. Useful Links

- [Pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Pub Points Scoring](https://pub.dev/help/scoring)
- [Semantic Versioning Guidelines](https://semver.org)
