# Releasing the parent-oss project

> WARN: Due to some internal tooling (releasability checks) semantic versioning is barely supported.
> 
> Therefore, a new release number has to be a new **major**.

Assume you want to release from version `70.0.0.x`, 
**the next version must be** `71.0.0.x`
1. Prepare a new project release in [Jira](https://sonarsource.atlassian.net/projects/PARENTOSS?selectedItem=com.atlassian.jira.jira-projects-plugin%3Arelease-page) with as version `71.0` (no patch or build number)

2. Leave the Jira version status as `UNRELEASED`
3. Update pom.xml version of parent-oss project. (example [PR](https://github.com/SonarSource/parent-oss/pull/158/files))
4. Check that releasability checks pass on [Burgr](https://burgr.sonarsource.com/projects/SonarSource/parent-oss/main)
5. Retrieve the last build number on [Burgr](https://burgr.sonarsource.com/projects/SonarSource/parent-oss/main) (`major.minor.patch.build-number`)
6. On GitHub create a new release and set this number retrieved from Burgr as tag and release version
7. Publish the release
8. Check that the [GitHub release workflow](https://github.com/SonarSource/parent-oss/actions/workflows/release.yml) run well 
9. Check it is gracefully deployed on [Sonatype](https://central.sonatype.com/artifact/org.sonarsource.parent/parent). 

> WARN: It can take up to 24h to have the release synchronized with Sonatype. Sometimes it is very fast sometimes not)
