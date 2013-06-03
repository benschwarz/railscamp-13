require.config({
  paths: {
    prefixfree:  '../components/prefix-free/prefixfree',
    domReady:    '../components/requirejs-domready/domReady',
    reqwest:     '../components/reqwest/src/reqwest',
    modernizr:   'vendor/modernizr.min',
    pinjs:       'vendor/pinjs'
  },
  shim: {
    modernizr: {
      exports: 'Modernizr'
    },
    prefixfree: {
      exports: 'StyleFix'
    }
  }
});
