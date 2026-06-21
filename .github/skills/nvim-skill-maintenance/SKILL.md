---
name: nvim-skill-maintenance
description: >-
  How to keep the .github/skills pack accurate when changing this Neovim config.
  Read this WHENEVER you edit any config file, add/remove/update a plugin, or
  hit a skill whose content contradicts the real code. Defines: which skill
  documents which source file (the file -> skill index), the ground-truth
  precedence rule for stale skills, pinned-rev drift detection, and the
  checklist for adding a skill when a new plugin is introduced.
covers:
  - .github/skills/**
---

# Keeping the skill pack up to date

The `.github/skills/` pack is a set of grounded notes about this config. It is a
**secondary source**. It only stays useful if every config change updates the
matching skill in the SAME change. This skill is the contract for doing that.

Three rules, one per situation:

## 1. Editing config -> update the matching skill in the same change

Before you finish ANY edit to a tracked file, look it up in the **file -> skill
index** below and open that `SKILL.md`. If your change alters anything the skill
documents (an option, a keymap, a command, a default, a gotcha, a pinned rev),
update the skill text to match. A change is not done until its skill is correct.

The mapping is also stored per-skill in each `SKILL.md` frontmatter as a
`covers:` list. The index below is the reverse view (file -> skill) and is
**generated** from those `covers:` lists — regenerate it, never hand-edit a row
(see "Regenerating the index").

### file -> skill index

| File                                  | Skill(s) to update                                |
| ------------------------------------- | ------------------------------------------------- |
| `.github/skills/**`                   | `nvim-skill-maintenance`                          |
| `after/queries/**/*.scm`              | `nvim-treesitter`                                 |
| `init.lua`                            | `nvim-config-overview`                            |
| `lua/config/autocmds.lua`             | `nvim-core-options-keymaps-autocmds`              |
| `lua/config/keymaps.lua`              | `nvim-core-options-keymaps-autocmds`              |
| `lua/config/lsp.lua`                  | `nvim-lsp`                                        |
| `lua/config/options.lua`              | `nvim-core-options-keymaps-autocmds`              |
| `lua/config/pack.lua`                 | `nvim-config-overview`, `nvim-pack-management`, `nvim-tree-sitter-manager` |
| `lua/plugins/99.lua`                  | `nvim-99`                                         |
| `lua/plugins/bufferline.lua`          | `nvim-misc-plugins`                               |
| `lua/plugins/colorizer.lua`           | `nvim-misc-plugins`                               |
| `lua/plugins/colorscheme.lua`         | `nvim-colorscheme`                                |
| `lua/plugins/completion.lua`          | `nvim-blink-cmp`                                  |
| `lua/plugins/conform.lua`             | `nvim-conform`                                    |
| `lua/plugins/fidget.lua`              | `nvim-misc-plugins`                               |
| `lua/plugins/flash.lua`               | `nvim-flash`                                      |
| `lua/plugins/gitsigns.lua`            | `nvim-gitsigns`                                   |
| `lua/plugins/jdtls.lua`               | `nvim-jdtls`                                      |
| `lua/plugins/js-i18n.lua`             | `nvim-misc-plugins`                               |
| `lua/plugins/lint.lua`                | `nvim-lint`                                       |
| `lua/plugins/lualine.lua`             | `nvim-lualine`                                    |
| `lua/plugins/mason.lua`               | `nvim-mason`                                      |
| `lua/plugins/minesweeper.lua`         | `nvim-misc-plugins`                               |
| `lua/plugins/mini.lua`                | `nvim-mini`                                       |
| `lua/plugins/neo-tree.lua`            | `nvim-neo-tree`                                   |
| `lua/plugins/octo.lua`                | `nvim-octo`                                       |
| `lua/plugins/render-markdown.lua`     | `nvim-render-markdown`                            |
| `lua/plugins/snacks.lua`              | `nvim-snacks`                                     |
| `lua/plugins/telescope.lua`           | `nvim-telescope`                                  |
| `lua/plugins/tmux-navigator.lua`      | `nvim-misc-plugins`                               |
| `lua/plugins/treesitter-textobjects.lua` | `nvim-treesitter`                              |
| `lua/plugins/trouble.lua`             | `nvim-trouble`                                    |
| `lua/plugins/tree-sitter-manager.lua` | `nvim-tree-sitter-manager`                        |
| `lua/plugins/whichkey.lua`            | `nvim-which-key`                                  |
| `lua/util/ai_argument.lua`            | `nvim-mini`                                       |
| `lua/util/ai_treesitter.lua`          | `nvim-mini`, `nvim-treesitter`                    |
| `lua/util/lsp_definition.lua`         | `nvim-jdtls`, `nvim-lsp`                          |
| `lua/util/path.lua`                   | `nvim-gitsigns`, `nvim-lualine`, `nvim-telescope` |
| `nvim-pack-lock.json`                 | `nvim-pack-management`                            |

Note: some files are covered by more than one skill (e.g. `lua/util/path.lua`
feeds telescope, lualine, and gitsigns). When you edit a shared file, update
EVERY skill listed for it.

## 2. Skill contradicts the code -> code wins, then fix the skill

Skills can drift. The precedence order when sources disagree is always:

1. The **real config file** (`lua/...`) as it exists right now.
2. The **installed plugin source/docs** under
   `~/.local/share/nvim/site/pack/core/opt/<dir>/` (`lua/`, `doc/*.txt`).
3. The **skill prose**.

If a skill claims something the live config or installed source contradicts,
trust the code, do the task correctly, then correct the skill in the same
change. Do not silently follow stale skill text, and do not delete a skill's
content just because one line is wrong — fix that line.

### Detecting drift with pinned revs

Every plugin skill cites a **pinned rev** that was current when it was written.
That rev is your staleness signal. Compare it to the live lockfile:

```bash
cd ~/.config/nvim
# rev a skill was written against (grep the skill body):
grep -iE 'rev|pin' .github/skills/<skill>/SKILL.md
# current pinned rev for that plugin:
grep -A3 '"<plugin-dir>"' nvim-pack-lock.json
```

If they differ, the plugin was updated after the skill was written: treat the
skill's API/option claims as **suspect until re-verified** against the installed
source, then update the skill's text and its cited rev. See
`nvim-testing-and-verification` for the verification workflow and
`nvim-pack-management` for how the lockfile and updates work.

## 3. New Tier-B plugin added -> author a new skill

A "Tier-B" plugin is any plugin substantial enough to get its own
`lua/plugins/<name>.lua` config module (as opposed to a tiny library or a
one-line game, which belong in `nvim-misc-plugins`). When you add one (see the
add-a-plugin steps in `nvim-pack-management`), creating its skill is part of the
definition of done:

1. Create `.github/skills/nvim-<name>/SKILL.md`.
2. Frontmatter: `name`, a `description` that includes trigger phrases, and a
   `covers:` list naming the new config file(s).
3. Body: match the shape and depth of an existing exemplar
   (`nvim-config-overview`, `nvim-testing-and-verification`, `nvim-telescope`):
   Role; What's configured (a faithful excerpt of the REAL setup/keymaps);
   Capabilities + examples; Gotchas/version notes (true only); Docs/ground truth
   (install path + `:help` tag + upstream URL + pinned rev); a runnable "Verify
   your change" recipe.
4. Ground every claim in the installed source — see
   `nvim-testing-and-verification`. Do not invent options or keymaps.
5. Add the new skill to the "one skill per plugin" list at the bottom of
   `nvim-config-overview`.
6. Regenerate the index in this file (below) and confirm the new file appears.

For a SMALL plugin (library dep or trivial game), do NOT make a new skill — add
a short entry to `nvim-misc-plugins` and list its config file under that skill's
`covers:` instead.

When a plugin is REMOVED: delete its `.github/skills/nvim-<name>/` dir (or its
`nvim-misc-plugins` entry), remove it from the overview list, and regenerate the
index.

## Regenerating the index

The file -> skill table above is derived from the `covers:` frontmatter of every
skill. After adding/removing a skill or editing any `covers:` list, regenerate
it and paste the output over the table:

```bash
cd ~/.config/nvim && python3 - <<'PY'
import re,glob,os
rev={}
for f in sorted(glob.glob('.github/skills/*/SKILL.md')):
    name=os.path.basename(os.path.dirname(f))
    fm=re.match(r'^---\n(.*?)\n---\n',open(f).read(),re.S).group(1)
    for blk in re.findall(r'covers:.*?\n((?:\s+-\s+.*\n)+)',fm+'\n'):
        for p in re.findall(r'-\s+(\S+)',blk):
            rev.setdefault(p,[]).append(name)
w=max(len(p) for p in rev)
for p in sorted(rev):
    skills=", ".join(f"`{s}`" for s in sorted(set(rev[p])))
    print(f"| `{p}`"+" "*(w-len(p))+f" | {skills} |")
PY
```

## Verify your change

Run from the repo root (`~/.config/nvim`):

```bash
# Every covers: path must exist, and every plugin/core/util file must be
# covered by at least one skill (no orphans).
cd ~/.config/nvim && python3 - <<'PY'
import re,glob,os
covered=set()
for f in glob.glob('.github/skills/*/SKILL.md'):
    fm=re.match(r'^---\n(.*?)\n---\n',open(f).read(),re.S).group(1)
    for blk in re.findall(r'covers:.*?\n((?:\s+-\s+.*\n)+)',fm+'\n'):
        for p in re.findall(r'-\s+(\S+)',blk):
            covered.add(p)
            if '*' not in p and not os.path.exists(p):
                print("MISSING PATH:",f,p)
allsrc={f"lua/plugins/{os.path.basename(x)}" for x in glob.glob('lua/plugins/*.lua')}
allsrc|={f"lua/config/{os.path.basename(x)}" for x in glob.glob('lua/config/*.lua')}
allsrc|={f"lua/util/{os.path.basename(x)}" for x in glob.glob('lua/util/*.lua')}
print("uncovered source files:", sorted(allsrc-covered) or "NONE")
PY
```

A clean run (no `MISSING PATH`, `uncovered source files: NONE`) means the index
and `covers:` lists are consistent with the tree.
