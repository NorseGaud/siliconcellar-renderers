# Silicon Cellar renderer packages

Direct3D translation layers for [Silicon Cellar](https://github.com/NorseGaud/SiliconCellar). Silicon Cellar downloads one package when a game recipe selects it, checks the SHA-256, and gives the folder to that game only. The Wine Engine ([NorseGaud/wine](https://github.com/NorseGaud/wine)) reads it from `HKCU\Software\Wine\AppDefaults\<game.exe>\SiliconCellar\DllPath`.

The files in each package are copies of the inputs below. They are not changed. Each package keeps the licence files of its input and has a `SOURCE.txt` with the input and its SHA-256.

## Packages

| Package | Version | Input | Input SHA-256 | Licence |
|---|---|---|---|---|
| `dxvk` | DXVK-Sikarugir-async-v1.10.3 | [Sikarugir-App/Wrapper](https://github.com/Sikarugir-App/Wrapper/releases/tag/v1.0) `Template-1.0.15.tar.xz`, folder `renderer/dxvk` | `34273bcce885ce5a7fd6937af9ea344bb9961de7d55d6193f7413142e835c8c3` | zlib (`LICENSE`) |
| `dxmt` | v0.80-213-g4ddb20e | the same Template, folder `renderer/dxmt` | the same | LGPL 2.1 (`LICENSE`). Source: [3Shain/dxmt](https://github.com/3Shain/dxmt) |
| `dxmt-v0.72` | v0.72 | [3Shain/dxmt v0.72](https://github.com/3Shain/dxmt/releases/tag/v0.72) `dxmt-v0.72-builtin.tar.gz` | `661eae8cc12c5ad900ecf3c76e7bacfda519b3eeb5ed5c44b48875b2373e89fe` | MIT (`LICENSE` from the v0.72 tag) |
| `d3dmetal` | 4.0 beta 2 | Apple "Evaluation environment for Windows games 4.0 beta 2" DMG, `redist/lib` | `6248a0edc61553790753e5e9c060b8e53c940ed197f11409dcc34a35e05becc1` | Apple EA18380 (`License.rtf`) |
| `d3dmetal-3.0` | 3.0 | Apple "Evaluation environment for Windows games 3.0" DMG, `redist/lib` | `d49395fb07e536804d1da0858590e53f6aa6fab12512e18fd80a74c87f9f063c` | Apple EA18380 (`License.rtf`) |

Package layout: `wine/x86_64-windows`, `wine/i386-windows`, `wine/x86_64-unix`, `external/` (D3DMetal only), licence files, `SOURCE.txt`. The SHA-256 of each archive is in `SHA256SUMS` in each release.

## D3DMetal

D3DMetal is Apple software. Apple's licence (EA18380, section 2A(iii) and 2C) permits distribution of `D3DMetal.framework` in its entirety and of files in `/redist`, only for non-commercial purposes, with all of Apple's notices. Silicon Cellar is free and open source. It shows Apple's licence and asks the user to accept it before a game uses D3DMetal. The licence permits use for "developing, testing, or evaluating video games" on Apple hardware only.

## Build

```sh
./build-packages.sh <4.0 beta 2 DMG> <3.0 DMG> out
```

The script downloads the Template and DXMT v0.72 into `.cache/` and checks every SHA-256, including the two DMGs. Apple's DMGs need an Apple ID, so you download them from [developer.apple.com](https://developer.apple.com/download/all/?q=evaluation%20environment) first.
