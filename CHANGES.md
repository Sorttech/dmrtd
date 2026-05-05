# CHANGES — Sort Group fork of dmrtd

This is a fork of [ZeroPass/dmrtd](https://github.com/ZeroPass/dmrtd) maintained
by Sort Group for use in our consumer-facing conveyancing onboarding mobile app.

It is published in compliance with LGPL-3.0 §3 (incorporating GPL-3.0 §5(a)),
which requires modified copies to "carry prominent notices stating that you
modified it, and giving a relevant date."

The library remains licensed under **LGPL-3.0** (see `LICENSE.LGPL`). The
parallel commercial licence in `LICENSE.COMMERCIAL` is an offering by the
upstream rights-holder ZeroPass and applies only to the upstream-original
work — see the header note at the top of that file.

---

## Fork point

- **Forked from**: [ZeroPass/dmrtd](https://github.com/ZeroPass/dmrtd) `master`
- **Initial fork date**: 2025-12-12

The exact upstream commit was not recorded at fork time; reconstruction
guidance is in the parent application's internal docs.

## Maintainer

Sort Group — Andrew Fowke (`andrew.fowke@sortgroup.co.uk`).

---

## Modifications vs. upstream

### 2026-05-05 — Public-fork preparation

Modifications carried over from the previously-private vendored copy:

- **New file `lib/src/utils/safe_hex.dart`** — null-safe hex formatter that
  accepts `Uint8List?`, `ByteBuffer`, `ByteData`, or any `Iterable<int>`,
  returning `''` for null. Used in place of the upstream `Uint8List.hex()`
  extension where the input may be nullable.

- **`lib/src/proto/pace.dart`** — replaced `data.hex()` / `_nonce.hex()`
  diagnostic log calls with `safeHex(...)` so logging cannot throw if the
  underlying buffer is null. Removed the now-unnecessary
  `package:dmrtd/extensions.dart` import; added explicit imports for
  `command_apdu.dart`, `response_apdu.dart`, and `safe_hex.dart`. No
  cryptographic logic changed.

- **`lib/src/proto/iso7816/icc.dart`** — adjusted the four
  `generalAuthenticatePACEstepN` helpers (and `setAT`) so they no longer
  raise `ICCError` on non-success status words. Callers (in `pace.dart`)
  now receive the raw response and inspect the status word themselves.
  This is required for the parent application's PACE fallback / Greek-
  passport SW=6300 recovery path (see ZeroPass/dmrtd issue #33). The
  previously-private `_transceive` was renamed to `transceive` to allow
  this.

- **`pubspec.yaml`** — pinned `flutter_nfc_kit` to exact version `3.6.2`
  (upstream uses a `^3.6.0-rc.6` range). Pinning avoids unintended uplifts
  during downstream `pub upgrade` runs while a known-good combination is
  in production.

- **`lib/dmrtd.dart`** — added a trailing newline at end of file (POSIX
  convention; no functional change).

- **Whole-tree `dart format`** — reformatted all `.dart` files in `lib/`,
  `test/`, `example/`, and `scripts/` to canonical Dart formatter output.
  No logic changes; reviewers comparing against upstream should run
  `dart format` on the upstream copy first to filter out the formatting
  noise.

### 2025-12-12 — Initial vendored fork

Imported as a single bulk commit into the parent application's
`third_party/dmrtd/` directory. Pre-existing modifications at the time of
import included the dependency renames to `crypto_keys_plus` and
`tripledes_nullsafety`, and various EU-passport read fixes carried in the
fork commit message ("fixed all the bugs, EU passports now work WIP").
The exact pre-import diff against ZeroPass master is not preserved in
this repository's git history.

---

## Re-establishing the upstream baseline

To inspect the precise differences against ZeroPass upstream:

```bash
git clone https://github.com/ZeroPass/dmrtd.git /tmp/dmrtd-upstream
diff -r --brief /tmp/dmrtd-upstream/lib lib
```

For files that differ, run a full `diff -u` and run `dart format` on both
copies first to filter formatting noise from semantic changes.
