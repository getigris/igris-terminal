# ig-term :: functions/smart-install.sh - Auto-detect package manager and install

smart-install() {
  if [[ -f "package.json" ]]; then
    if [[ -f "pnpm-lock.yaml" ]]; then
      pnpm install
    elif [[ -f "yarn.lock" ]]; then
      yarn install
    elif [[ -f "package-lock.json" ]]; then
      npm install
    elif [[ -f "bun.lockb" ]] || [[ -f "bun.lock" ]]; then
      bun install
    elif [[ -f "deno.json" ]] || [[ -f "deno.jsonc" ]]; then
      deno install
    elif [[ -f "jspm.config.js" ]] || [[ -d "jspm_packages" ]]; then
      jspm install
    elif [[ -d ".meteor" ]]; then
      meteor npm install
    elif [[ -f "rush.json" ]]; then
      rush install
    elif [[ -f "lerna.json" ]]; then
      lerna bootstrap
    else
      echo "Node.js project detected. No lockfile found, using npm."
      npm install
    fi
  elif [[ -f "pom.xml" ]]; then
    mvn install
  elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    gradle build
  elif [[ -f "Cargo.toml" ]]; then
    cargo build
  elif [[ -f "go.mod" ]]; then
    go mod download
  elif [[ -f "requirements.txt" ]]; then
    pip install -r requirements.txt
  elif [[ -f "pyproject.toml" ]]; then
    pip install -e .
  elif [[ -f "Gemfile" ]]; then
    bundle install
  elif [[ -f "composer.json" ]]; then
    composer install
  elif ls *.csproj 1>/dev/null 2>&1 || ls *.sln 1>/dev/null 2>&1; then
    dotnet restore
  else
    echo "No supported project detected."
    return 1
  fi
}

alias i="smart-install"
