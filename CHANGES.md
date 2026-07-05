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

### 2026-07-05 — Production-readiness fixes

Repo-wide review and fix pass. `dart analyze` is now clean (0 errors,
0 warnings) and enforced in CI; all tests pass, including the PACE
known-answer suites which previously did not run.

**File reading / session layer**

- **`lib/src/proto/mrtd_api.dart`** — fixed crash when reading files larger
  than 32 KB (extended READ BINARY branch now taken at offset `0x7FFF`);
  added a progress guard so a data-less warning response can no longer spin
  `_readBinary` in an infinite loop; fixed the SFI→FID fallback map (the
  bogus `0x82 → 0x0002` entry collided with DG2, EF.CardAccess now maps to
  `0x011C`); guarded null/empty first-chunk responses with `MrtdApiError`;
  added `resetMaxRead()`; resolved stale TODOs.
- **`lib/src/proto/mrtd_sm.dart`** — SSC is now incremented for every
  received protected response, including error/data-less ones (previously
  desynced the session); `protect()` no longer mutates the caller's
  `CommandAPDU` (clones via new `CommandAPDU.copy()`); response MAC compared
  in constant time.
- **`lib/src/proto/iso7816/icc.dart`** — guarded null response data in
  `readBinaryExt`; command APDU bytes now logged only via the
  sensitive-data-gated log path.
- **`lib/src/proto/iso7816/command_apdu.dart`** — added `copy()`.
- **`lib/src/proto/iso7816/response_apdu.dart`** — removed dead
  `StatusWord.cla` getter.
- **`lib/src/com/nfc_provider.dart`** — `connect()` now throws
  `NfcProviderError` on non-ISO7816 tags instead of silently returning;
  `disconnect()` calls `FlutterNfcKit.finish()` before clearing state so a
  failed finish can be retried.
- **`lib/src/passport.dart`** — session state (`_dfSelected`, max-read) is
  reset at the start of `startSession`/`startSessionPACE`; `BACError`/
  `PACEError`/`SMError` are wrapped into `PassportError` per the documented
  contract; `readEfCardAccess()` no longer swallows connection loss;
  lifecycle documented; stale/incorrect doc comments fixed.

**Cryptography / PACE**

- **`lib/src/proto/pace.dart`** — PACE nonce decryption for 3DES suites no
  longer strips ISO 9797-1 padding from the raw nonce (`paddedData: false`);
  DH KDF seed encoded fixed-width to the prime length; auth tokens compared
  in constant time.
- **`lib/src/crypto/aes.dart`** — `AESChiperSelector` returns the AES-192
  cipher for 192-bit keys (previously returned AES-128, breaking all
  AES-192 PACE suites).
- **`lib/src/utils.dart`** — `bigIntToUint8List`/`bigIntToByteData` gained
  fixed-width (`length:`) encoding per ICAO 9303 field-size rules.
- **`lib/src/proto/public_key_pace.dart`, `ecdh_pace.dart`, `dh_pace.dart`**
  — EC points and DH values are wire-encoded fixed-width (leading zero
  bytes preserved); received EC public keys validated on-curve and
  not-at-infinity.
- **`lib/src/proto/bac.dart`** — decrypted `R` (contains K.ICC) moved to the
  sensitive-data-gated log path; E.ICC MAC compared in constant time.
- **`lib/src/crypto/crypto_utils.dart`** — added `constantTimeEquals`.
- **`lib/src/crypto/des.dart`** — `_bytesToDWordList` honours
  `offsetInBytes` for byte views.

**Parsing robustness (untrusted chip data)**

- **`lib/src/lds/tlv.dart`** — declared TLV lengths validated against the
  available buffer (`TLVError` instead of `RangeError`); multi-byte tags
  capped at 4 bytes.
- **`lib/src/lds/ef.dart`** — `ElementaryFile.fromBytes` converts any
  thrown object (including `Error`s such as `RangeError`/`TypeError`) into
  `EfParseError`, covering every EF/DG parser.
- **`lib/src/lds/mrz.dart`** — extended document number and date parsing
  throw `MRZParseError` on malformed input instead of
  `FormatException`/`RangeError`.
- **`lib/src/extension/string_apis.dart`** — date parsing rejects invalid
  calendar dates (e.g. month 13, Feb 30) instead of silently rolling over.
- **`lib/src/lds/df1/efdg2.dart`** — bounds checks throughout the biometric
  record parser; multiple biometric templates now advance correctly;
  3-byte fields (featureMask/poseAngle) read fully; FAC magic-byte check
  fixed (`||` not `&&`).
- **`lib/src/lds/df1/efdg11.dart`, `efdg12.dart`** — UTF-8 decoded with
  `allowMalformed: true`.
- **`lib/src/lds/efcard_access.dart`, `substruct/pace_info.dart`** —
  unguarded `as` casts and `!` replaced with checked parsing;
  `parameterId` is now correctly OPTIONAL per the ASN.1 spec.
- **`lib/src/lds/tlvSet.dart`** — decode errors rethrown as `TLVError`
  instead of silently truncating.
- **`lib/src/lds/df1/efcom.dart`** — DG tag list sanity-checked.
- **`lib/src/crypto/iso9797.dart`** — `unpad` bounded (no `RangeError` on
  all-zero buffers).
- **`lib/src/crypto/aa_pubkey.dart`** — empty subject-public-key data
  rejected explicitly.
- **`lib/src/types/data.dart`** — removed unused `dart:ffi` import; tag and
  length overflow now throw instead of silently truncating.

**API surface / packaging**

- **`lib/dmrtd.dart`** — now exports `CanKey` and the typed errors
  `BACError`, `PACEError`, `SMError`; **`lib/internal.dart`** now exports
  `pace.dart`.
- **`pubspec.yaml`** — removed unused dependencies `expandable`,
  `diffie_hellman`, `crypto_keys_plus`; added `repository`; version bumped
  to 2.0.1.
- **`LICENSE`** (new) — official LGPL-3.0 text; **`COPYING`** (new) —
  GPL-3.0 text (LGPL-3.0 incorporates it by reference).
- **`.github/workflows/test.yml`** — updated to maintained action versions;
  added `dart analyze --fatal-warnings` gate.
- **`test/`** — `pace_test_dh.dart`/`pace_test_ecdh.dart` renamed to
  `pace_dh_test.dart`/`pace_ecdh_test.dart` so the default test runner
  discovers them; removed key-material prints from test output; added
  regression tests for the parsing and encoding fixes.
- **`example/`** — PACE-without-EF.CardAccess no longer null-crashes;
  read button disabled while a read is in progress; iOS alert-message
  calls awaited; proper `dispose()`; dead code removed; sensitive-data
  logging off by default; `intl` declared.

### 2026-06-23 — Remove archive dependency

- **`lib/src/lds/mrz.dart`** — replaced the `archive` package's byte reader
  with an inlined minimal MRZ byte reader; **`pubspec.yaml`** — dropped the
  `archive` dependency. No behavior change.

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
