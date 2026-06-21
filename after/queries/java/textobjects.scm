; extends
; Two things upstream's query does not provide for mini.ai:
;
; 1. Records, interfaces and enums are not captured as @class, so ac/ic
;    (dac/dic/yac/...) ignore them. Capture them like classes.
; 2. @block.inner: upstream defines @block.outer (and method bodies) but no
;    block.inner, so `io` (inside block) has nothing to select.
;
; function.inner / class.inner for plain classes come from upstream via the
; #make-range! directive, which util.ai_treesitter resolves, so they need no
; override here.

(record_declaration
  body: (class_body) @class.inner) @class.outer

(interface_declaration
  body: (interface_body) @class.inner) @class.outer

(enum_declaration
  body: (enum_body) @class.inner) @class.outer

(block
  "{"
  (_)+ @block.inner
  "}")
