# Contributing

Welcome! This guide covers how work gets from a ticket into Zedu Desktop: forks, branches, pull requests, CI, and review. If you've never used these conventions before, don't worry. Read it through once, keep it handy for your first few PRs, and it'll start to feel natural quickly.

---

## The workflow at a glance

There are three repos in the chain, and you only ever work in the bottom one:

```
zeduchat/zedu-desktop              Zedu's repo. Reviewers send batches here.
  └─ zedu-hng/zedu-desktop         Review org. Your PRs land on `dev` here.
       └─ <your-team>/zedu-desktop Your team's fork. You work here.
```

| Branch in `zedu-hng` | Purpose | Who merges |
|---|---|---|
| `dev` (default) | All PRs land here, from teams and reviewers alike. | Reviewers, squash merge |
| `staging` | What's ready to go to Zedu; mirrors `zeduchat:staging`. | Reviewers promote `dev` → `staging` |

The full cycle for any piece of work:

1. Pick up an **approved** ticket in ClickUp or Linear. No ticket, no work.
2. Sync your fork's `dev` from `zedu-hng`.
3. Create a ticket branch, do the work, and test it against your team's backend.
4. Push. Tier 1 CI runs in your fork; get it green.
5. Open a PR from your ticket branch into `zedu-hng/zedu-desktop:dev`.
6. Address review feedback. Once approved, reviewers squash-merge it into `dev`.
7. Reviewers promote `dev` → `staging` and send it to Zedu. Verify, then close the ticket.

---

## One-time setup (per team)

1. Fork **`zedu-hng/zedu-desktop`** into your team's GitHub org. Not `zeduchat`: forking the wrong one points your PRs and **Sync fork** at the wrong repo.
2. In the fork, go to **Actions** and enable workflows. Forks have them off by default, and Tier 1 CI runs there.
3. Optional: to have CI builds use your team's config, add a repository variable `APP_ENV_FILE` (**Settings → Secrets and variables → Actions → Variables**) containing your full `.env`. Without it, CI uses `.env.example`.
4. Each contributor clones the **team fork**:

```bash
git clone https://github.com/<your-team>/zedu-desktop.git
cd zedu-desktop
cp .env.example .env
flutter pub get
flutter run
```

See the README for configuration and platform setup. Never commit `.env`.

To use your team's backend, set `API_BASE_URL` in your `.env` (or pass `--dart-define=API_BASE_URL=...`). Without it, the app uses Zedu staging (`https://api.staging.zedu.chat/api/v1/`).

---

## Working on a ticket

```bash
# 1. Sync the fork: GitHub "Sync fork" button on your fork's dev, then:
git checkout dev
git pull origin dev

# 2. Create your ticket branch
git checkout -b feat/123-dark-mode-toggle

# 3. Do work, commit
git add <files>
git commit -m "feat: add toggle component"

# 4. Push to your fork (runs Tier 1 CI), then open a PR into zedu-hng:dev
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

Your PR title becomes the commit message on `dev` when it's squash-merged. This convention is called [Conventional Commits](https://www.conventionalcommits.org/).

---

## Testing

Run the same checks CI runs:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

Build and run on at least one desktop target (`flutter build macos|windows|linux`).

**What tests you need:**

- **Non-UI code** (business logic, state management, services/API layer, utilities): unit tests for what the ticket changed.
- **UI code:** a widget test for the changed widget. Integration tests only for new or changed *critical* flows (auth, payments, anything data-destructive).
- **Only what your ticket touched.** Not retroactive coverage of pre-existing untested code in the same file. If you notice a real gap, file a separate ticket.

For UI changes, also check the relevant window sizes, keyboard navigation, accessibility labels, and loading, empty and error states.

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

## CI: two tiers

**Tier 1: your fork, on every push.** Pushing any branch to your fork runs:

- format, analyze and test;
- the vulnerability, forbidden-pattern and Lazarus scans;
- unsigned macOS, Windows and Linux builds.

It all uses your fork's own Actions minutes, which are free and unlimited on public repos. **Don't open a PR until Tier 1 is green.** Link the passing run in your PR.

**Tier 2: `zedu-hng`, after review.** On your PR, the checks run on every push, but the desktop builds don't. When a reviewer is ready to try your change, they add the **`ready-for-build`** label. That builds all three platforms once and posts download links and install notes on the PR. To rebuild after new pushes, a reviewer removes and re-adds the label.

On a first-time contribution, a maintainer has to approve the workflow run before anything runs.

---

## Opening the PR

Open the PR from your fork's **ticket branch** into **`zedu-hng/zedu-desktop:dev`**. Don't open it from your fork's `dev`: that drags in everything else merged there.

Fill out the PR template (`.github/PULL_REQUEST_TEMPLATE.md`). It loads automatically when you open a PR. The short version:

- **Ticket**: link to the ClickUp or Linear ticket.
- **What changed / Why**: the outcome, and the problem it solves.
- **How to test / What to expect**: steps a reviewer can follow, and the result they should see.
- **Test evidence**: your Tier 1 run link, the backend you tested against, and the tests you added or updated.
- **Screenshots / recording**: for any visible or interactive change.
- **AI usage**: one line, if AI was used significantly.

Skip sections that don't apply, but write "N/A because…" so your reviewer can see you thought about it.

---

## Keeping your branch up to date

While you're working, `dev` will move forward as other PRs land. Pull those changes into your branch periodically, especially before opening your PR.

**We use `merge` for this, not `rebase`.** Sync your fork's `dev` first (GitHub **Sync fork** button), then:

```bash
git checkout feat/123-dark-mode-toggle
git fetch origin
git merge origin/dev

# Resolve any conflicts, commit them, push
git push
```

### Why merge and not rebase?

Both are valid ways to stay in sync. Here's the honest tradeoff:

- **Merge** is safer and conceptually simpler. You never rewrite history, so if you get something wrong, nothing is lost. The downside is that your branch ends up with "Merge branch 'dev'…" commits in its history.
- **Rebase** produces a cleaner history but requires `git push --force-with-lease`, and getting it wrong on a shared branch can cause people to lose work.

Because we **squash-merge** PRs into `dev`, the messy merge commits in your branch get thrown away anyway. So we get the clean-history benefit *without* the rebase risk.

---

## How PRs land

- **1 reviewer approval** is required, and it must come after your last push.
- All review threads must be resolved. Don't resolve a thread without actually addressing it.
- Contributors don't merge their own PRs.
- Reviewers **squash-merge** into `dev`: all your commits become one commit, with your PR title as the message. So commit as often and as messily as you like on your branch, but make the PR title good.

After merge, reviewers promote `dev` → `staging` with a merge commit, and send `staging` to `zeduchat` in batches. The ticket goes **MERGED → VERIFIED → CLOSED** once the change is verified.

---

## Security and secrets

Never commit:

- API keys or tokens;
- passwords or private keys;
- signing certificates or provisioning profiles;
- cloud or database credentials;
- `.env` files with real values;
- user data.

`.env` is bundled into the app as an asset, so anything in it is readable by anyone who has the app. Real secrets belong on the backend.

If you expose a secret, deleting it in the next commit is not enough. Tell a reviewer immediately so it can be rotated.

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
- **Push often.** Pushed code is backed up, and every push runs Tier 1.
- **Open PRs in draft mode** if you want early feedback before the work is done.
- **Keep PRs small.** A PR with 50 lines of change gets reviewed in 10 minutes. A PR with 500 lines gets a rubber-stamp review or sits for days.
- **If you're stuck, ask.** Use your team channel first, then the project channel. For a blocker, include:
  - the ticket number;
  - what you tried to do;
  - what happened, with the error or build output;
  - what you already tried;
  - what help you need.

---

## Quick reference

```bash
# Start new work (after "Sync fork" on your fork's dev)
git checkout dev
git pull origin dev
git checkout -b feat/123-your-feature

# Save progress (every push runs Tier 1 CI in your fork)
git add <files>
git commit -m "feat: message"
git push

# Update from dev while working
git fetch origin
git merge origin/dev

# Ready for review
# → Tier 1 green, then open a PR from your branch into zedu-hng/zedu-desktop:dev
```
