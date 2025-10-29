# GitHub Actions Workflows

This directory contains automated CI/CD workflows for the Dita2epub project.

## Workflows

### 1. CI - Build and Test (`ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual dispatch

**Jobs:**

#### Unit Tests
- **Platforms:** Ubuntu, Windows, macOS
- **Java Versions:** 17, 21
- **Tests:** EpubValidatorTest, FontEmbeddingTest (unit tests only)
- **Duration:** ~5 minutes
- **No DITA-OT Required**

#### Integration Tests
- **Platforms:** Ubuntu, Windows
- **Java Version:** 17
- **Tests:** All 44 tests including DITA-OT integration
- **Duration:** ~15-20 minutes
- **Requires:** DITA-OT 4.3.5 (auto-downloaded)

#### Build
- **Platforms:** Ubuntu
- **Java Versions:** 17, 21
- **Output:** JAR artifacts
- **Duration:** ~3 minutes

#### Code Quality
- **Platform:** Ubuntu
- **Checks:** Checkstyle, code formatting
- **Duration:** ~2 minutes

#### Test Summary
- **Aggregates:** All test results
- **Output:** GitHub Step Summary with overview

**Artifacts:**
- Unit test results (30 days)
- Integration test results (30 days)
- Generated EPUBs (7 days)
- Build artifacts (30 days)

---

### 2. Nightly Tests (`nightly-tests.yml`)

**Triggers:**
- Scheduled: 2 AM UTC daily
- Manual dispatch

**Jobs:**

#### Comprehensive Tests
- **Platforms:** Ubuntu, Windows, macOS
- **Java Versions:** 17, 21
- **Tests:** All tests with coverage reports
- **Duration:** ~30 minutes per matrix job

**Additional Checks:**
- Test with sample DITA content
- Generate sample EPUBs
- Code coverage with JaCoCo

**Artifacts:**
- Test results with coverage (30 days)
- Generated EPUBs (7 days)

**Notifications:**
- Creates GitHub Step Summary on failure
- Can be extended to send email notifications

---

### 3. Release (`release.yml`)

**Triggers:**
- Tag push matching `v*` (e.g., `v1.0.1`)
- Manual dispatch with version input

**Jobs:**

#### Validate Release
- Build and test the release
- Install plugin in DITA-OT
- Generate and validate sample EPUB

#### Build Release Artifacts
- Create plugin ZIP file
- Generate SHA256 checksums
- Upload artifacts

#### Create GitHub Release
- Extract release notes from RELEASE_NOTES.md
- Create GitHub release with artifacts
- Attach checksums

#### Publish Plugin
- Notification step for manual publication
- Provides instructions for DITA-OT registry submission

**Artifacts:**
- Plugin ZIP (90 days)
- Checksums (90 days)

**Creating a Release:**
```bash
# Tag the release
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin v1.0.1

# Or use manual dispatch from GitHub UI
```

---

### 4. Documentation (`docs.yml`)

**Triggers:**
- Push to `main` with markdown changes
- Pull requests with markdown changes
- Manual dispatch

**Jobs:**

#### Validate Documentation
- Check all markdown links
- Verify required documentation files
- Count code examples

#### Check Spelling
- Spell check all markdown and Java files
- Uses custom dictionary in `.github/cspell.json`

#### Generate Documentation Report
- Creates comprehensive documentation summary
- Reports statistics and validation results

**Configuration Files:**
- `.github/markdown-link-check-config.json` - Link checker settings
- `.github/cspell.json` - Spell checker dictionary

---

## Matrix Testing Strategy

### Unit Tests Matrix
```
OS: [ubuntu-latest, windows-latest, macos-latest]
Java: [17, 21]
= 6 combinations
```

### Integration Tests Matrix
```
OS: [ubuntu-latest, windows-latest]
Java: [17]
= 2 combinations
```

### Nightly Tests Matrix
```
OS: [ubuntu-latest, windows-latest, macos-latest]
Java: [17, 21]
= 6 combinations (comprehensive)
```

**Total Matrix Jobs:** 14 combinations across all workflows

---

## Artifacts Retention

| Artifact Type | Retention | Workflows |
|--------------|-----------|-----------|
| Test Results | 30 days | CI, Nightly |
| Build Artifacts | 30 days | CI, Release |
| Generated EPUBs | 7 days | CI, Nightly |
| Release Assets | 90 days | Release |

---

## Usage Examples

### Running CI Manually

1. Go to Actions tab
2. Select "CI - Build and Test"
3. Click "Run workflow"
4. Select branch
5. Click "Run workflow"

### Creating a Release

1. **Update version** in relevant files
2. **Update RELEASE_NOTES.md** with changes
3. **Commit and push** to main
4. **Create and push tag:**
   ```bash
   git tag -a v1.0.1 -m "Release v1.0.1"
   git push origin v1.0.1
   ```
5. **Workflow automatically:**
   - Validates the release
   - Builds artifacts
   - Creates GitHub release
   - Provides publication instructions

### Viewing Test Results

**Option 1: GitHub Actions UI**
- Go to Actions tab
- Click on workflow run
- View test summary in job output

**Option 2: Artifacts**
- Download test report artifacts
- Open `build/reports/tests/test/index.html`

**Option 3: Step Summary**
- Scroll to bottom of workflow run
- View Test Summary section

---

## Troubleshooting

### Unit Tests Failing

**Check:**
1. Java version compatibility
2. Gradle wrapper permissions (Linux/Mac)
3. Test class syntax and imports

**Debug:**
```bash
./gradlew test --tests EpubValidatorTest --info
```

### Integration Tests Skipped

**Cause:** DITA-OT not available

**Solutions:**
1. Verify DITA_HOME environment variable
2. Check DITA-OT download in workflow
3. Verify plugin installation step

### Release Workflow Fails

**Common Issues:**
1. RELEASE_NOTES.md not updated
2. Version mismatch in files
3. Tag format incorrect (must be `v*`)

**Fix:**
```bash
# Delete incorrect tag
git tag -d v1.0.1
git push origin :refs/tags/v1.0.1

# Create correct tag
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin v1.0.1
```

---

## Configuration Files

### `.github/markdown-link-check-config.json`
Configures markdown link validation:
- Ignored patterns
- Timeout settings
- Retry behavior
- Acceptable status codes

### `.github/cspell.json`
Configures spell checking:
- Custom dictionary
- Ignored paths
- Language settings

---

## Best Practices

### For Contributors

1. **Run tests locally** before pushing:
   ```bash
   ./gradlew test
   ```

2. **Check documentation** links:
   ```bash
   # Install markdown-link-check
   npm install -g markdown-link-check
   markdown-link-check README.md
   ```

3. **Verify formatting** before commit

### For Maintainers

1. **Review test results** for all matrix combinations
2. **Check artifacts** for generated EPUBs
3. **Monitor nightly tests** for regressions
4. **Update workflows** when adding new test classes

---

## Monitoring

### Health Checks

- **Daily:** Review nightly test results
- **Weekly:** Check artifact storage usage
- **Monthly:** Review workflow performance
- **Per Release:** Validate all matrix combinations pass

### Metrics to Track

- Test pass rate by platform
- Average workflow duration
- Artifact sizes
- EPUB generation success rate

---

## Future Enhancements

### Planned Improvements

- [ ] Coverage reporting with Codecov
- [ ] Performance benchmarking
- [ ] Automatic dependency updates (Dependabot)
- [ ] Security scanning (Snyk, CodeQL)
- [ ] EPUB validation with EPUBCheck in CI
- [ ] Automatic changelog generation
- [ ] Slack/Discord notifications

---

## Support

For issues with GitHub Actions:
1. Check workflow logs
2. Review [GitHub Actions Documentation](https://docs.github.com/en/actions)
3. Open issue with `ci` label
4. Contact maintainers

---

**Last Updated:** October 29, 2025
**Maintained By:** J. Jeanne
