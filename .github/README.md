# Fast Delivery - GitHub Actions CI/CD

This repository uses GitHub Actions for automated testing, building, and deployment.

## 🤖 Workflows

### 1. Flutter CI/CD (`flutter-ci.yml`)
**Triggers**: Push to `main` or `develop`, Pull Requests to `main`

**Jobs**:
- **Test & Analyze**: Runs tests, formats code, analyzes for errors
- **Build Android APK**: Creates release APK (downloadable from Artifacts)
- **Build App Bundle**: Creates AAB for Play Store (only on `main` branch)

**What it does**:
- ✅ Verifies code formatting
- ✅ Runs `flutter analyze`
- ✅ Executes all tests with coverage
- ✅ Uploads coverage to Codecov
- ✅ Builds Android APK
- ✅ Builds Android App Bundle (main branch only)

### 2. Code Quality (`code-quality.yml`)
**Triggers**: Push to `main` or `develop`, Pull Requests to `main`

**What it does**:
- ✅ Checks for outdated packages
- ✅ Runs dart analyze
- ✅ Verifies pubspec.yaml
- ✅ Generates code statistics

## 📊 Viewing Results

1. Go to your GitHub repository
2. Click the **Actions** tab
3. See all workflow runs and their status
4. Click any run to see detailed logs
5. Download build artifacts (APK/AAB) from successful runs

## 🎯 Status Badges

Add these to your README.md to show build status:

```markdown
![Flutter CI](https://github.com/Hubert24hrs/FastDelivery/workflows/Flutter%20CI%2FCD/badge.svg)
![Code Quality](https://github.com/Hubert24hrs/FastDelivery/workflows/Code%20Quality/badge.svg)
```

## 🚀 How to Use

### Automatic Builds
Every time you push code:
```bash
git add .
git commit -m "Your changes"
git push origin main
```

GitHub Actions will automatically:
1. Run all tests
2. Check code quality
3. Build APK (if tests pass)
4. Upload artifacts

### Download APK
1. Go to Actions tab
2. Click on latest successful workflow run
3. Scroll to **Artifacts** section
4. Download `fast-delivery-apk`

### Pull Request Checks
When you create a PR:
- Tests must pass before merging
- Code quality checks must pass
- Build must succeed

## 🔒 Security Notes

- Secrets (API keys, signing keys) should be stored in GitHub Secrets
- Never commit `.env` or sensitive files
- Use `GITHUB_TOKEN` for authentication (automatically provided)

## 🛠️ Customization

### Change Flutter Version
Edit `.github/workflows/flutter-ci.yml`:
```yaml
flutter-version: '3.24.0'  # Change this
```

### Add More Jobs
Add to `.github/workflows/flutter-ci.yml`:
```yaml
  your-job:
    name: Your Job Name
    runs-on: ubuntu-latest
    steps:
      - name: Your step
        run: echo "Hello!"
```

### Skip CI for Specific Commits
Add to commit message:
```bash
git commit -m "Minor typo fix [skip ci]"
```

## 📈 Best Practices

1. **Always run tests locally** before pushing
2. **Keep workflows fast** (< 10 minutes)
3. **Use caching** to speed up builds
4. **Monitor workflow costs** (free tier: 2,000 min/month)
5. **Review failed runs immediately**

## 🎉 Benefits

- ✅ Catch bugs before they reach production
- ✅ Automated testing on every commit
- ✅ Consistent build environment
- ✅ Easy APK downloads for testing
- ✅ Team collaboration with confidence
- ✅ Code quality enforcement

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
