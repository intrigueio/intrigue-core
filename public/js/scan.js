(function($) {
  "use strict";

  function prepScanRunner() {
    // http://stackoverflow.com/questions/1420881/how-to-extract-base-url-from-a-string-in-javascript
    if (typeof location.origin === 'undefined') {
      location.origin = location.protocol + '//' + location.host;
    }

    // clear the entity type field
    $('#entity_type').empty()

    //get the list of scans and rewrite the scan entities
    $.getJSON(location.origin + "/v1/scans.json", function(data) {
      //console.log(data);
      $.each(data, function(key,obj) {

        //console.log(obj);

        if(obj["name"] == $('#scan_type option:selected').val()){
          console.log("Using allowed_types from " + obj["name"])

          // we have the correct scan_object, so populate the form
          $.each(obj["allowed_types"], function(key,allowed_type) {
            $('#entity_type')
               .append($("<option></option>")
               .attr("value",allowed_type)
               .text(allowed_type));
          });
        };
      });
    });

  }

  // Update the form on load
  $("document").ready(
  function() {
    prepScanRunner();
  });

  // Update the form on task change
  $("#scan_type").on("change", prepScanRunner);

}(jQuery));
