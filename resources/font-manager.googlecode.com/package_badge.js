package_badge = function(package, element) {
  $.getJSON("http://api.oswatershed.org/api/0.1/package.json?cb=?", {package: package}, function(data) {
			$(element).css({"font-family": "sans-serif"})
      $(element).append('<a href="http://oswatershed.org/" target="_blank"><img style="border: none; padding-right: 4px;" src="http://static.oswatershed.org/small_logo.png" /></a>');
      $(element).append('<a style="color: black; text-decoration: none;" id="pkglink" href="http://oswatershed.org/pkg/'+data.package+'" target="_blank"></a>');
      $(element+" #pkglink").append(data.package);
      $(element+" #pkglink").append('<strong> '+data.latest+'</strong>');
      $.each(data.distros, function(i,distro) {
	$(element+" #pkglink").append('<img style="border: none; padding-left: 8px; padding-right: 4px;" src="http://static.oswatershed.org/'+distro.logo+'" />');
	if (distro.uptodate)
	  $(element+" #pkglink").append('<strong>'+distro.version+'</strong>');
	else
	  $(element+" #pkglink").append(distro.version);
      });
     }, "jsonp");
}

tracking_data = {}

start_tracking = function(package, element) {
	$.getJSON("http://127.0.0.1:8000/pkg/"+package+"/track?cb=?", {'action': 'is_tracked'}, function(data) {
			tracking_data[package] = data.status;
			if (data.status == 'tracked') {
				$(element).append('<a id="tracking_link">untrack</a>');
			} else if (data.status == 'untracked') {
				$(element).append('<a id="tracking_link">track</a>');
			}
			$('#tracking_link').click( function() {toggle_track(package,element);});
			$(element).append(data.status+"<br>");
     }, "jsonp");
}

toggle_track = function(package, element) {
	var action = "is_tracked";
	if (tracking_data[package] == "tracked") {
		action = "untrack";
	} else if (tracking_data[package] == "untracked") {
		action = "track";
	}
  $.getJSON("http://127.0.0.1:8000/pkg/"+package+"/track?cb=?", {'action': action}, function(data) {
			tracking_data[package] = data.status;
      if (data.status == 'tracked') {
				$('#tracking_link').text("untrack");
			} else if (data.status == 'untracked') {
				$('#tracking_link').text("track");
			}
     }, "jsonp");
}
