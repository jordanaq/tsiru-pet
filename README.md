# tsiru.pet

The source for the personal site at <https://tsiru.pet> — [Zola] static site,
consumed by the `cloud-server` flake as a pinned input and served straight out
of the Nix store by Caddy. Nothing runs at runtime: no service, no database.

```sh
make check    # the gate — see below
make serve    # build, then http://127.0.0.1:8791
```

| Path | What |
|---|---|
| `content/` | pages. `_index.md` is the home page; `resume.md` is `/resume/` |
| `data/` | content that is a *list* — `projects.toml`, `resume.toml`, `github.toml` |
| `templates/` | Tera templates. `page.html` is the archetype every page extends |
| `static/` | assets copied verbatim — `style.css`, `avatar.jpg`, favicons, `og.png` |
| `og/card.html` | source for the social card; not served (rendered by `make og`) |
| `scripts/` | the guards and generators below |

## Conventions

**Styling lives in one place; pages pass content.** The cause of every visual
bug this site has had was a page expressing an opinion about its own styling.
So:

- **Never write styling in a template.** No `<style>`, no `style="…"`. All CSS
  is `static/style.css`, and it should be reached through classes.
- **Never write raw sizes.** Colour, spacing and type are tokens in `:root`.
  If you need a new value, add a token — don't inline a `0.95rem`.
- **Page-specific CSS is a smell.** If two pages need different values, the
  shared component should own the value and the pages should differ only in
  *content*.
- **Never copy the header into a page.** Extend `templates/page.html`:

  ```
  {% extends "page.html" %}
  {% block subtitle %}one line of inline content{% endblock %}
  {% block actions %}<a href="/">Home</a>{% endblock %}
  {% block body %}…sections…{% endblock %}
  ```

  The hero exists once, in `page.html`. Two pages can only differ in the two
  slots they fill, so they cannot drift apart.
- **Listy content is data, not markup.** Add a `data/*.toml` file and render it
  through `_card.html` / `_section.html` rather than hand-writing elements.

## The gate

`make check` is the canonical command. It runs, in order:

1. `nix flake check` — realizes the site derivation. Catches broken templates,
   missing data files, and (the trap that bites most) **untracked files**: the
   Nix build only sees files git knows about, so stage new files before
   building.
2. `scripts/check-conventions.sh` — fails if hero markup appears outside
   `page.html`, if a template carries `<style>` or `style="…"`, or if a
   declaration uses a raw `font-size` instead of a token.
3. `scripts/check-layout.py` — renders every page and asserts the shared
   header geometry is identical. This is the guard for the "avatar sits 1.5px
   differently" class of bug. It skips (with a warning) if chromium is absent.

`make lint-css` runs stylelint for the mechanical CSS rules; it is not part of
`make check` so the gate stays hermetic.

## Regenerating things

```sh
make og          # re-render static/og.png from og/card.html
./scripts/fetch-github-projects.sh   # refresh data/github.toml + the avatar
```

Both write committed artifacts. Re-run them only when their inputs change, and
commit the result — the Nix build never touches the network.

[Zola]: https://www.getzola.org/