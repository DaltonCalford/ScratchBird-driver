# Driver Package Submission Guide (0.1.0)

This guide maps built artifacts to their package registries and shows how to publish.

Built artifacts are in:

- `release/packages/`
- `release/packages/SHA256SUMS.txt`

## 1. npm (Node.js)

- Package: `scratchbird`
- Artifact: `release/packages/npm/scratchbird-0.1.0.tgz`
- Publish:
  - `cd tracks/alpha/drivers/node`
  - `npm login`
  - `npm publish /absolute/path/to/release/packages/npm/scratchbird-0.1.0.tgz --access public`
- Registry/support:
  - <https://www.npmjs.com/>
  - <https://docs.npmjs.com/creating-and-publishing-unscoped-public-packages>
  - <https://www.npmjs.com/support>

## 2. PyPI (Python)

- Package: `scratchbird`
- Artifacts:
  - `release/packages/python/scratchbird-0.1.0-py3-none-any.whl`
  - `release/packages/python/scratchbird-0.1.0.tar.gz`
- Publish:
  - `python3 -m venv .venv_release`
  - `. .venv_release/bin/activate`
  - `python -m pip install twine`
  - `python -m twine check release/packages/python/*`
  - `python -m twine upload release/packages/python/*`
- Registry/support:
  - <https://pypi.org/>
  - <https://packaging.python.org/en/latest/tutorials/packaging-projects/>
  - <https://pypi.org/help/>

## 3. NuGet (.NET)

- Package: `ScratchBird.Data`
- Artifact: `release/packages/nuget/ScratchBird.Data.0.1.0.nupkg`
- Publish:
  - `dotnet nuget push release/packages/nuget/ScratchBird.Data.0.1.0.nupkg --api-key <NUGET_API_KEY> --source https://api.nuget.org/v3/index.json`
- Registry/support:
  - <https://www.nuget.org/>
  - <https://learn.microsoft.com/nuget/nuget-org/publish-a-package>
  - <https://www.nuget.org/policies/Contact>

## 4. RubyGems (Ruby)

- Package: `scratchbird`
- Artifact: `release/packages/rubygems/scratchbird-0.1.0.gem`
- Publish:
  - `gem signin`
  - `gem push release/packages/rubygems/scratchbird-0.1.0.gem`
- Registry/support:
  - <https://rubygems.org/>
  - <https://guides.rubygems.org/publishing/>
  - <https://help.rubygems.org/>

## 5. crates.io (Rust)

- Package: `scratchbird`
- Artifact: `release/packages/crates/scratchbird-0.1.0.crate`
- Publish:
  - `cargo login <CRATES_IO_TOKEN>`
  - `cd tracks/alpha/drivers/rust`
  - `cargo publish`
- Registry/support:
  - <https://crates.io/>
  - <https://doc.rust-lang.org/cargo/reference/publishing.html>
  - <https://users.rust-lang.org/>

## 6. Packagist (PHP / Composer)

- Package: `scratchbird/pdo-scratchbird`
- Artifact (optional distribution zip):
  - `release/packages/composer/scratchbird-pdo-scratchbird-*.zip`
- Publish model:
  - Packagist normally indexes your VCS repository and tags (not manual zip upload).
  - Create/push git tag `v0.1.0` in the package repo.
  - Submit package URL once at Packagist, then updates are from tags/webhook.
- Registry/support:
  - <https://packagist.org/>
  - <https://packagist.org/about#how-to-update-packages>
  - <https://packagist.org/packages/submit>

## 7. Maven Central (JDBC)

- Package coordinates in current build:
  - Group: `com.scratchbird`
  - Version: `0.1.0`
- Artifacts:
  - `release/packages/maven/scratchbird-jdbc-0.1.0.jar`
  - `release/packages/maven/scratchbird-jdbc-0.1.0-sources.jar`
- Publish model:
  - Maven Central requires namespace setup, signed artifacts, and a configured publishing pipeline.
  - Current repo builds jars but does not yet include Central signing/publish wiring.
- Registry/support:
  - <https://central.sonatype.com/>
  - <https://central.sonatype.org/publish/publish-guide/>
  - <https://central.sonatype.org/faq/>

## 8. CRAN (R)

- Package: `scratchbird`
- Artifact: `release/packages/cran/scratchbird_0.1.0.tar.gz`
- Submit:
  - Follow CRAN checks and policy.
  - Submit to CRAN (new package submissions are handled through CRAN process; historically via email to `cran-submissions@r-project.org`).
- Registry/support:
  - <https://cran.r-project.org/>
  - <https://cran.r-project.org/web/packages/policies.html>
  - <https://cran.r-project.org/web/packages/submission_checklist.html>

## 9. Hex (Elixir)

- Package: `scratchbird_ecto`
- Artifact: `release/packages/hex/scratchbird_ecto-0.1.0.tar`
- Publish:
  - `cd tracks/p3/drivers/elixir`
  - `mix hex.user auth`
  - `mix hex.publish`
- Registry/support:
  - <https://hex.pm/>
  - <https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html>
  - <https://hexdocs.pm/hex/Mix.Tasks.Hex.User.html>

## 10. Swift Package Manager

- Artifact: `release/packages/swift/ScratchBird-0.1.0-source.zip`
- Publish model:
  - SwiftPM packages are distributed from git tags.
  - Create and push tag `0.1.0` (or `v0.1.0`) in the package repository.
  - Optionally submit to Swift Package Index for discovery.
- Registry/support:
  - <https://www.swift.org/package-manager/>
  - <https://swiftpackageindex.com/add-a-package>

## 11. Dart (pub.dev)

- Current status:
  - `tracks/beta/drivers/dart/pubspec.yaml` has `publish_to: 'none'`, so publish is intentionally disabled.
- To publish:
  - Remove `publish_to: 'none'`.
  - Run `dart pub publish --dry-run`.
  - Run `dart pub publish`.
- Registry/support:
  - <https://pub.dev/>
  - <https://dart.dev/tools/pub/publishing>

## Maintainer Reach-Out Checklist

For each registry, ensure these are ready before first publish:

- Account ownership established for project maintainers.
- 2FA enabled on maintainer accounts (`npm`, `PyPI`, `NuGet`, `RubyGems`, `crates.io`, `Hex`).
- API tokens stored in CI secrets for repeatable releases.
- Package names reserved and verified (some ecosystems already have similarly named packages).
- Public release notes and changelog for `0.1.0`.
