//////////////////////////////////////////////////////////////
function onCreate() {
  ShowToast();
}

//▬▬▬▬▬▬▬▬▬▬ //
// LINK JOIN //
//▬▬▬▬▬▬▬▬▬▬ //

function Profile() {
	setTimeout(function() {
	  window.open('https://t.me/BellaTrix_cs', 'ultimate')},
	100);
  }

function ServiceSSH() {
	setTimeout(function() {
	  window.open('./service/Update/Akun_SSH_Websocket.html', 'ultimate')},
	100);
  }

function ServiceXray() {
	setTimeout(function() {
	  window.open('./service/Update/Akun_Xray.html', 'ultimate')},
	100);
  }

  function MT() {
    setTimeout(function() {
      window.open('../../error.html', 'ultimate')},
    100);
    }

function DarkMode() {
  var element = document.body;
  element.classList.toggle("dark-mode");
}

//▬▬▬▬▬▬▬▬▬▬ //
//   TOAST   //  
//▬▬▬▬▬▬▬▬▬▬ //
function ShowToast() {
  var x = document.getElementById("Toast");
  x.className = "show";
  setTimeout(function(){ x.className = x.className.replace("show", ""); }, 3900);
}
//▬▬▬▬▬▬▬▬▬▬ //
// FPS WEBS  //
//▬▬▬▬▬▬▬▬▬▬ //
 var fps = document.getElementById("fps");

var startTime = Date.now();

var frame = 0;

function tick() {

  var time = Date.now();

  frame++;

  if (time - startTime > 1000) {

      fps.innerHTML = (frame / ((time - startTime) / 1000)).toFixed(1);

      startTime = time;

      frame = 0;

	}  window.requestAnimationFrame(tick);

}

tick();

