class_name TowerDB
extends RefCounted
## Data-driven definitions for the 100-floor Celestial Ascent Tower.
## Ten themed regions, one unique Floor Master per floor, bilingual names.
## Pure static data: zero scene build cost, headless-testable.

# Keep tower configuration deterministic so test runs and save restoration agree.
const FLOOR_COUNT := 100