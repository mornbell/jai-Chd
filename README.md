# CHD Perfect Hash Function

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A minimal perfect hash function (MPHF) implementation based on the **CHD** (Compress, Hash, Displace) algorithm, originally described in:

> _"Hash, Displace, and Compress"_ by Djamal Belazzougui, Fabiano C. Botelho, and Martin Dietzfelbinger (ESA 2009).

## What is a Perfect Hash Function?

A **perfect hash function** maps a set of _n_ keys to a set of _m_ integers without collisions. If _m = n_, it is a **minimal perfect hash function (MPHF)**. CHD generates an MPHF that:

- Uses **~2.0–2.5 bits per key** (space-efficient).
- Supports **O(1) lookup** time.
- Requires **O(n)** construction time.

## How CHD Works

CHD operates in three phases:

1. **Compress** – Hash each key into a bucket using a first-level hash function. Keys in the same bucket form a "group".
2. **Hash** – For each bucket, try different hash function seeds (via a second-level hash family) until all keys in the bucket map to distinct positions in a global displacement table.
3. **Displace** – Store the chosen seed (displacement value) for each bucket. During lookup, compute the bucket, retrieve the seed, and compute the final hash.

The result is a small data structure (a packed array of displacement values) that can be used to compute the rank of any key in the original set.

## Usage Example (C)

[examples](exmaples/)
