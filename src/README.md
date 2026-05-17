# Source

Source code will live here after the project records upstream provenance and
chooses the first build strategy.

Proposed layout:

```text
src/
|-- boot/
|-- kernel/
|-- arch/
|   `-- x86_64/
|-- drivers/
|-- fs/
|-- graphics/
|-- libc/
|-- shell/
`-- apps/
```

Do not import upstream source into this directory without updating
`docs/legal-and-provenance.md` and the source inventory under `research/`.
