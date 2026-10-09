<!-- markdownlint-disable MD013 MD033 MD041 -->
<!-- Sonar Marketing hosts these approved brand assets on its Kentico Kontent CDN (assets-eu-01.kc-usercontent.com). Shared URLs are intentional; consult Marketing before replacing them. -->
<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://assets-eu-01.kc-usercontent.com/ef593040-b591-0198-9506-ed88b30bc023/a23fc7ba-23f0-489a-829d-ed88c0748521/Sonar_Logo_Dark%20Backgrounds.svg">
    <img src="https://assets-eu-01.kc-usercontent.com/ef593040-b591-0198-9506-ed88b30bc023/82c13eba-d95c-4bb8-8007-7ce77c14e043/Sonar_Logo_Light%20Backgrounds.svg" alt="Sonar logo" width="400">
  </picture>
</p>
<!-- markdownlint-enable MD013 MD033 MD041 -->

<!-- sonar-marketing:start -->
<!-- Marketing maintains this section. For wording changes, consult the relevant
Product Marketing Manager (PMM). Repository CODEOWNERS review accuracy and merge
changes. -->

# Parent POM for Sonar public projects

This repository contains the shared Maven parent project for Sonar public
projects. It provides common build configuration for maintainers; the release
instructions below explain how its artifacts reach Maven Central.

To learn more about Sonar products, visit the
[Sonar website](https://www.sonarsource.com/).

<!-- sonar-marketing:end -->

## License

Copyright 2009-2026 SonarSource.

Licensed under the [GNU Lesser General Public License, Version 3.0](http://www.gnu.org/licenses/lgpl.txt)

## Releasing

After the build artifacts get promoted to the releases repository on repox,
they get automatically uploaded to Maven Central.

The release process is described in [RELEASE.md](./RELEASE.md)
