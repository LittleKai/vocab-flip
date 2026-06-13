# Stroke Data Sources

## Primary Source: animCJK
- **Description:** A comprehensive open-source project providing vector stroke data (SVG paths) and median arrays for drawing and animating CJK characters.
- **Coverage:** Japanese Kanji, Kana, Chinese Simplified, and Chinese Traditional.
- **Format:** JSONL files located under `animCJK/graphicsJa.txt`, `graphicsJaKana.txt`, `graphicsZhHans.txt`, and `graphicsZhHant.txt`.
  - Records have `character`, `strokes` (list of SVG path strings), and `medians` (list of point arrays `[x,y]`).
- **License:** Arphic Public License (APL) / MIT / LGPL / Unihan depending on the character subset. See `animCJK/licenses/` for specifics.

## Fallback / Secondary Sources

### hanzi-writer-data / makemeahanzi
- **Description:** Stroke paths and medians for Chinese characters. This acts as a fallback source for missing characters in Chinese Traditional/Simplified.
- **License:** Arphic Public License (APL) for data derived from Arphic PL Fonts.

### kanjivg
- **Description:** Used primarily for kanji component references and alternative stroke orders.
- **License:** Creative Commons Attribution-ShareAlike 3.0.

## Disclaimer on Inkstone
- **Inkstone:** While Inkstone provides advanced rendering logic and grading, its code is licensed under **GPL**.
- **Decision:** No Inkstone GPL code is copied into this project. The geometry math and validation algorithms inside VocabFlip (Phase 3) were written entirely in pure Dart from scratch using established geometry principles (like Frechet distance and Cosine Similarity) and are completely free of GPL dependencies.

## Locale Mapping
During database generation, animCJK files are mapped to the following app locales:
- `graphicsJa.txt` -> `ja`
- `graphicsJaKana.txt` -> `ja-kana`
- `graphicsZhHans.txt` -> `zh-Hans`
- `graphicsZhHant.txt` -> `zh-Hant`