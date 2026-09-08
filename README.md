# scoop-neko

[![CI](https://github.com/NekoAria/scoop-neko/actions/workflows/ci.yml/badge.svg)](https://github.com/NekoAria/scoop-neko/actions/workflows/ci.yml)
[![Excavator](https://github.com/NekoAria/scoop-neko/actions/workflows/excavator.yml/badge.svg)](https://github.com/NekoAria/scoop-neko/actions/workflows/excavator.yml)

A personal [Scoop](https://scoop.sh) bucket maintained by [NekoAria](https://github.com/NekoAria).

## Usage

Add the bucket:

```powershell
scoop bucket add neko https://github.com/NekoAria/scoop-neko
```

Install a manifest:

```powershell
scoop install neko/<manifest>
```

Available manifests can be found in the [`bucket`](./bucket) directory.

## Contributing

Issues and pull requests are welcome. Before contributing a manifest, read the Scoop [Contributing Guide](https://github.com/ScoopInstaller/.github/blob/main/.github/CONTRIBUTING.md) and [App Manifests](https://github.com/ScoopInstaller/Scoop/wiki/App-Manifests) documentation.

When reporting a hash mismatch, use the provided issue template and keep the issue title in this format:

```text
<manifest>@<version>: hash check failed
```

## License

This repository is released under the [Unlicense](./LICENSE).
