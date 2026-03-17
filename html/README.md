# html

Generated HTML documentation and any web-based interfaces for AdaPACE.

The files in this directory are typically produced by `gnatdoc` or a similar documentation tool from the annotated source in `src/`.  Hand-authored HTML pages (tutorials, API guides) may also live here.

## Regenerating documentation

```
gnatdoc -P src/adapace.gpr --output=html
```

Do **not** edit generated files directly; update the source annotations instead.
