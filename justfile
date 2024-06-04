init := "tests/minimal.lua"

test:
  nvim --headless --noplugin -u {{init}} \
    -c "PlenaryBustedDirectory tests { minimal_init = '{{init}}', sequential=true }"

health:
  nvim -c "checkhealth render-markdown" -- .

demo-all: demo-heading demo-list demo-box demo-latex demo-callout

demo-heading:
  just demo "heading_code" "30" "## Heading 2"

demo-list:
  just demo "list_table" "30" ""

demo-box:
  just demo "box_dash_quote" "15" ""

demo-latex:
  just demo "latex" "15" ""

demo-callout:
  just demo "callout" "30" ""

demo file rows content:
  rm -f demo/{{file}}.gif
  python demo/record.py \
    --cols "55" \
    --rows {{rows}} \
    --file demo/{{file}}.md \
    --cast {{file}}.cast \
    --content "{{content}}"
  # https://docs.asciinema.org/manual/agg/usage/
  agg {{file}}.cast demo/{{file}}.gif \
    --font-family "Monaspace Neon,Hack Nerd Font" \
    --last-frame-duration 1
  rm {{file}}.cast

update:
  python -Wignore scripts/update.py

gen-doc:
  # https://github.com/kdheepak/panvimdoc
  # https://pandoc.org/
  ../../open-source/panvimdoc/panvimdoc.sh \
    --project-name render-markdown \
    --input-file README.md \
    --vim-version 0.10.0

[private]
gen-file-text:
  #!/usr/bin/env python
  for i in range(100_000):
    level = "#" * ((i % 6) + 1)
    print(f"{level} Title {i}\n")

gen-large-file:
  just gen-file-text > large.md
