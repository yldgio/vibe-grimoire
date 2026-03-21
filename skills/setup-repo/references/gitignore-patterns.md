# .gitignore Patterns by Stack

Always include the **Universal** section. Add stack-specific sections based on what you detect in the project.

---

## Universal (always include)

```gitignore
# --- OS Artifacts ---
.DS_Store
.DS_Store?
._*
Thumbs.db
desktop.ini
ehthumbs.db

# --- Editor Artifacts ---
.vscode/
.idea/
*.swp
*.swo
*.orig
*.bak
*~
.history/

# --- Secrets & Credentials ---
.env
.env.local
.env.*.local
*.pem
*.key
*.p12
*.pfx
secrets/
.secrets/

# --- General ---
*.log
tmp/
temp/
*.tmp
coverage/
```

---

## Python

```gitignore
# --- Python ---
__pycache__/
*.py[cod]
*.so
.venv/
venv/
env/
.Python
*.egg-info/
.eggs/
dist/
build/
.mypy_cache/
.ruff_cache/
.pytype/
.pytest_cache/
.coverage
htmlcov/
.tox/
.nox/
```

## Node / TypeScript / JavaScript

```gitignore
# --- Node ---
node_modules/
dist/
build/
.next/
.nuxt/
.svelte-kit/
.astro/
*.tsbuildinfo
.turbo/
.parcel-cache/
.cache/
.yarn/cache
.pnp.*
```

## Go

```gitignore
# --- Go ---
/bin/
*.test
coverage.out
coverage.html
```

## Rust

```gitignore
# --- Rust ---
/target/
```

## .NET / C#

```gitignore
# --- .NET ---
bin/
obj/
.vs/
*.user
*.suo
*.userosscache
*.sln.docstates
TestResults/
*.nupkg
*.snupkg
```

## Java / Kotlin / Gradle

```gitignore
# --- Java / Gradle ---
build/
.gradle/
target/
*.class
*.jar
*.war
*.ear
.idea/
*.iml
out/
```

## Ruby

```gitignore
# --- Ruby ---
.bundle/
vendor/bundle/
*.gem
.rbenv-version
.ruby-version
```

## PHP

```gitignore
# --- PHP ---
vendor/
```

## Swift / iOS / macOS

```gitignore
# --- Swift / Xcode ---
.build/
DerivedData/
*.xcworkspace/
Pods/
*.ipa
*.dSYM.zip
*.dSYM
xcuserdata/
```

## C / C++

```gitignore
# --- C / C++ ---
*.o
*.a
*.so
*.dylib
*.exe
*.out
build/
cmake-build-*/
CMakeFiles/
CMakeCache.txt
```

## Terraform / OpenTofu

```gitignore
# --- Terraform ---
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
!*.tfvars.example
override.tf
override.tf.json
```

## Docker

```gitignore
# --- Docker ---
.dockerignore
```

## Generated output (add if dist/ or out/ dirs are present)

```gitignore
dist/** linguist-vendored
out/** linguist-vendored
```
