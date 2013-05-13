define(function() {

  // Returns a single matching element from the document or given DOM element
  function $(sel, ctx)  {
    return (ctx || document).querySelector(sel);
  }

  // Returns the matching elements from the document or given DOM element
  function $$(sel, ctx) {
    return [].slice.call((ctx || document).querySelectorAll(sel));
  }

  return {
    "$": $,
    "$$": $$
  };

});
