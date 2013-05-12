(function() {
  "use strict";

  function $(sel, ctx)  { return (ctx || document).querySelector(sel); }
  function $$(sel, ctx) { return [].slice.call((ctx || document).querySelectorAll(sel)); }
  function docReady(element, callback) {
    document.addEventListener('DOMContentLoaded', function() {
      var e = $(element);
      if (e) callback(e);
    }, false);
  }

  docReady('html.register form', function(form) {

    form.addEventListener('submit', function(e) {

      e.preventDefault();

      var form = e.currentTarget,
          card = pinCardAttributes(form);

      Pin.createToken(card, function(response) {
        if (response.response) {
          appendCardToken(form, response);
          form.submit();
        } else {
          showPinError(response.error_description, response.messages);
        }
      });

    }, false);

  });

  function pinCardAttributes(form) {
    var card = {};

    // Extract all the Pin card details
    $$("[data-pin]", form).forEach(function(input) {

      // Expiry text field needs munging
      if (input.dataset.pin == 'expiry') {
        var expiry = input.value.split("/");
        card.expiry_month = expiry[0];
        card.expiry_year = expiry[1];
        if (card.expiry_year.length == 2)
          card.expiry_year = "20" + card.expiry_year;
      }

      // Everything else passes through directly
      else {
        card[input.dataset.pin] = input.value;
      }

    });

    return card;
  }

  function appendCardToken(form, response) {
    function appendHiddenInput(name, value) {
      var input = document.createElement('input');
      input.type = 'hidden'; input.name = name; input.value = value;
      form.appendChild(input);
    }
    appendHiddenInput('entrant[card_token]', response.response.token);
    appendHiddenInput('entrant[ip_address]', response.ip_address);
  }

  function showPinError(description, messages) {
    console.log(description, messages);
    // TODO
  }

})();
