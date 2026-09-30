# Contributing

Welcome! This guide covers how work gets from a ticket into `zeduchat/zedu-desktop`: forks, branches, pull requests, and review. If you've never used these conventions before, don't worry. Read it through once, keep it handy for your first few PRs, and it'll start to feel natural quickly.

---

## The workflow at a glance

You never work in `zeduchat/zedu-desktop` directly. Your team forks it, you work and review in the fork, and finished tickets come back to us as PRs into `staging`.

```
zeduchat/zedu-desktop:main      ← promoted from staging by maintainers
zeduchat/zedu-desktop:staging   ← your PR lands here (squash-merged)
        ↑ PR from your fork's ticket branch
<your-team>/zedu-desktop        ← your team's fork: branch, review, CI
```

The full cycle for any piece of work:

1. Pick up an **approved** ticket in ClickUp or Linear. No ticket, no work.
2. Sync your team's fork with `zeduchat/staging`.
3. Create a ticket branch in the fork and do the work.
4. Open a PR inside your fork. Fork CI passes and your team reviews and merges it there.
5. Open a PR from the same ticket branch to `zeduchat/zedu-desktop:staging`.
6. Address review feedback. Once approved, we squash-merge it into `staging`.
7. Verify on the staging build, then close the ticket.

---

## One-time setup (per team)

1. Fork `zeduchat/zedu-desktop` into your team's GitHub org.
2. In the fork, go to **Actions** and enable workflows. Forks have them off by default, and you need fork-side CI.
3. Each contributor clones the **team fork**:

```bash
git clone https://github.com/<your-team>/zedu-desktop.git
cd zedu-desktop
cp .env.example .env
flutter pub get
flutter run
```

See the README for configuration (`.env`, `--dart-define`) and platform setup. Never commit `.env`.

---

## Working on a ticket

```bash
# 1. Sync the fork: GitHub "Sync fork" button on your fork (from zeduchat/staging), then:
git checkout staging
git pull origin staging

# 2. Create your ticket branch
git checkout -b feat/123-dark-mode-toggle

# 3. Do work, commit
git add <files>
git commit -m "feat: add toggle component"

# 4. Push to your fork and open a PR in the fork
git push -u origin feat/123-dark-mode-toggle
```

---

## Branch naming

Format: `type/<ticket-id>-short-description`

```
feat/123-dark-mode-toggle
fix/245-crash-on-empty-project
chore/190-bump-flutter
refactor/301-extract-file-loader
docs/110-setup-instructions
```

**Types:**

| Type       | When to use it                                              |
|------------|-------------------------------------------------------------|
| `feat`     | New functionality the user can see                          |
| `fix`      | Bug fix                                                     |
| `refactor` | Restructuring code without changing behaviour               |
| `chore`    | Dependency bumps, config changes, build tweaks              |
| `docs`     | Documentation only                                          |
| `test`     | Adding or fixing tests, no production code change           |
| `perf`     | Performance improvement                                     |
| `security` | Security hardening                                          |

**Rules:**

- Always include the ticket ID from ClickUp or Linear.
- Lowercase, hyphen-separated. No spaces, no underscores, no camelCase.
- 3–5 words after the ticket ID. The PR title carries the full description.
- No personal names (`remi/dark-mode` is an anti-pattern; git already knows who you are).
- One ticket per branch. If you find another problem, open another ticket.

---

## PR titles

Format: `type: short description in present tense, lowercase`

```
feat: add dark mode toggle to settings
fix: prevent crash when opening empty project
refactor: extract file loader into its own module
chore: bump flutter to 3.41.5
docs: explain how to run tests on windows
```

**Rules:**

- Same `type` prefix as your branch. If the branch is `feat/...`, the PR is `feat: ...`.
- **Present tense, imperative mood.** "add", not "added" or "adds". It reads as a command: *this PR will add dark mode*.
- Lowercase after the colon.
- No period at the end.
- Aim for 50 characters, hard cap at 72.

This convention is called [Conventional Commits](https://www.conventionalcommits.org/).

---

## Before you open any PR

Run the same checks CI runs:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

CI also runs a Trivy vulnerability scan, a forbidden-pattern scan, and the Lazarus scanner, and builds macOS, Windows, and Linux.

For UI changes, also check the relevant window sizes, keyboard navigation, and loading, empty, and error states.

Then self-review:

```bash
git status
git diff
```

Check that:

- only intended files changed;
- debug code is gone;
- no secrets are committed;
- tests cover what this ticket changed.

---

## Review inside your team's fork

1. Open a PR in your fork: your ticket branch → your fork's `staging` (or whatever integration branch your team uses).
2. Fork CI must pass. It's the same workflows as upstream, running in your fork.
3. Your team reviews and merges it in the fork.

---

## Opening the PR to `zeduchat`

Open the PR from your fork's **ticket branch** to **`zeduchat/zedu-desktop:staging`**. Don't open it from your fork's `staging`: that drags in every other ticket your team merged since the last sync.

Fill out the PR template (`.github/PULL_REQUEST_TEMPLATE.md`). It loads automatically when you open a PR. The short version:

- **Ticket**: link to the ClickUp or Linear ticket.
- **What changed / Why**: the outcome, and the problem it solves.
- **How to test / What to expect**: steps a reviewer can follow, and the result they should see.
- **Test evidence**: your fork CI run and fork PR links, plus the tests you added or updated.
- **Screenshots / recording**: for any visible or interactive change.
- **AI usage**: one line, if AI was used significantly.

Skip sections that don't apply, but write "N/A because…" so your reviewer can see you thought about it.

On a first-time contribution, a maintainer has to approve the workflow run before CI starts. Once the builds finish, a bot comments on your PR with download links for the unsigned macOS, Windows, and Linux builds, so reviewers can run your change without building it.

---

## Keeping your branch up to date

While you're working, `staging` will move forward as other PRs land. Pull those changes into your branch periodically, especially before opening your PR to `zeduchat`.

**We use `merge` for this, not `rebase`.** Sync your fork first (GitHub **Sync fork** button), then:

```bash
git checkout feat/123-dark-mode-toggle
git fetch origin
git merge origin/staging

# Resolve any conflicts, commit them, push
git push
```

### Why merge and not rebase?

Both are valid ways to stay in sync. Here's the honest tradeoff:

- **Merge** is safer and conceptually simpler. You never rewrite history, so if you get something wrong, nothing is lost. The downside is that your branch ends up with "Merge branch 'staging'…" commits in its history.
- **Rebase** produces a cleaner history but requires `git push --force-with-lease`, and getting it wrong on a shared branch can cause people to lose work.

Because we **squash-merge** PRs into `staging`, the messy merge commits in your branch get thrown away anyway. So we get the clean-history benefit *without* the rebase risk.

---

## How PRs land in `staging`

Review rules on `zeduchat`:

- **2 approvals** are required, and approval must come after your last push.
- All review threads must be resolved. Don't resolve a thread without actually addressing it.
- Required CI checks must pass.
- Contributors don't merge their own PRs.

When your PR is approved, we **squash-merge** it. This means:

- All your commits get combined into a single commit on `staging`.
- The commit message on `staging` will be your PR title.
- `staging`'s history stays linear and readable: one commit per PR.

So commit as often and as messily as you like on your ticket branch. Your **PR title** is what ends up in the history forever, so take a few seconds to make it good.

After merge, the ticket goes **MERGED → VERIFIED** (checked on the staging build) **→ CLOSED**.

---

## Security and secrets

Never commit:

- API keys or tokens;
- passwords or private keys;
- cloud or database credentials;
- user data.

`.env` is bundled into the app as an asset, so anything in it is readable by anyone who has the app. Real secrets belong on the backend.

If you expose a secret, deleting it in the next commit is not enough. Tell a maintainer immediately so it can be rotated.

---

## AI usage

AI is fine for explaining code, drafting implementations, tests, debugging, refactoring, and docs. You're still responsible for the output.

Don't:

- paste generated code you haven't read;
- submit code you can't explain;
- give AI tools secrets or user data;
- treat AI output as a substitute for testing or review.

For significant AI-assisted changes, add one line to the PR saying how AI was used.

---

## A few extra tips

- **Pull before you start work each day.** It saves you from a painful merge later.
- **Push often.** Pushed code is backed up; unpushed code lives only on your laptop.
- **Open PRs in draft mode** if you want early feedback before the work is done.
- **Keep PRs small.** A PR with 50 lines of change gets reviewed in 10 minutes. A PR with 500 lines gets a rubber-stamp review or sits for days.
- **If you're stuck, ask.** Use your team channel first, then the project channel. For a blocker, include:
  - the ticket number;
  - what you tried to do;
  - what happened, with the error or log output;
  - what you already tried;
  - what help you need.

---

## Quick reference

```bash
# Start new work (after "Sync fork" on GitHub)
git checkout staging
git pull origin staging
git checkout -b feat/123-your-feature

# Save progress
git add <files>
git commit -m "feat: message"
git push

# Update from staging while working
git fetch origin
git merge origin/staging

# Ready for review
# → PR in your fork first, then a PR from the same branch to zeduchat/zedu-desktop:staging
```
