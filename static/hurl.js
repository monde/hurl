/* props and shout out to http://urltea.com/ */
urlbox_default = "type/paste url here";
window.onload = function () {
	// add event to url
	var urlbox = document.getElementById('url');
		if (urlbox) {
		urlbox.onfocus = function () {
			this.className = '';
			if (this.value == urlbox_default) {
				this.value = "http://";
				this.select();
			}
		}
		urlbox.onblur = function () {
			if (this.value == "" || this.value == "http://" || this.value == urlbox_default) {
				this.value = urlbox_default
				this.className = 'empty';
			}
		}
		if (urlbox.value == "") {
			urlbox.onblur();
		} else {
			urlbox.onfocus();
		}
	}

	var hurlform = document.getElementById('hurlform');
	if (hurlform) {
		hurlform.onsubmit = function () {
			urlbox = document.getElementById('url');
			if (urlbox && (urlbox.value == "" || urlbox.value == urlbox_default || urlbox.value == 'http://')) {
				alert("Enter a URL or get flogged by the alert box!\n\nYou've been warned.");
				return false;
			}
		}
	}
}
