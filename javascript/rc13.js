define(["modernizr", "prefixfree", "pages/register"], function(modernizr, prefixfree, registerPage) {

  // Ghetto router
  if (window.location.pathname == '/register') {
    registerPage();
  }

  // Initialize the fonts
  require(["https://use.typekit.net/rey0bbe.js"], function() {
    Typekit.load();
  });

});
