require.config({
  paths: {
    modernizr:   '../components/modernizr/modernizr',
    prefixfree:  '../components/prefix-free/prefixfree',
    domReady:    '../components/requirejs-domready/domReady',
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
