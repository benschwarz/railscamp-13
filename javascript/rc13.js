define(["modernizr", "prefixfree", "services/typekit", "services/google_analytics", "pages/register"],
  function(modernizr, prefixfree, typekit, googleAnalytics, registerPage) {

    typekit();
    googleAnalytics();

    // Ghetto router
    if (window.location.pathname == '/register') {
      registerPage();
    }

  }
);
