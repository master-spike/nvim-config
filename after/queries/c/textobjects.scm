; extends
; Upstream provides @block.outer for compound_statement but no block.inner, so
; mini.ai's `io` (inside block) has nothing to select. Add a real capture.
; (function.inner/class.inner/etc. come from upstream via #make-range!, which
; util.ai_treesitter resolves, so they need no override here.)
(compound_statement
  "{"
  (_)+ @block.inner
  "}")
