# GitHub CLI token renewal

`gh` authenticates via a GitHub App installation token that expires after 1 hour.
If a `gh` command fails with an auth error, run this to renew:

```bash
source /home/hermes/.hermes/.env
header=$(printf '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '=\n' | tr '/+' '_-')
now=$(date +%s)
payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$((now-60))" "$((now+600))" "$GITHUB_APP_ID" \
  | base64 | tr -d '=\n' | tr '/+' '_-')
sig=$(printf '%s.%s' "$header" "$payload" \
  | openssl dgst -sha256 -sign /home/hermes/.hermes/github_app.pem | base64 | tr -d '=\n' | tr '/+' '_-')
jwt="${header}.${payload}.${sig}"

install_id=$(curl -sf \
  -H "Authorization: Bearer $jwt" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

token=$(curl -sf -X POST \
  -H "Authorization: Bearer $jwt" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/${install_id}/access_tokens" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

printf '%s' "$token" | gh auth login --with-token --hostname github.com
```

After running this, retry the original `gh` command.

## GitHub App token permissions via `gh api`

The `gh api repos/<owner>/<repo>` endpoint (and `gh repo view --json permissions`) returns
unreliable `permissions` fields when authenticated with a **GitHub App installation token**
(`ghs_...` prefix). It may show `push: false`, `pull: false`, etc. even when the GitHub App
has read/write access to code and pull requests, and the actual git operations (push, PR create)
**succeed fine**.

**Do not trust these API fields to determine if a GitHub App can push or create PRs.**
Instead, attempt the actual operation — if the GitHub App has the permission granted in its
app settings, git operations will work even if the REST API metadata says otherwise.
