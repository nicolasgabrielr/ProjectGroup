window.onload = function(){
      (function(){
        var show = function(el){
          return function(msg){ el.innerHTML = msg; }
        }(document.getElementById('msgs'));
        var ws       = new WebSocket('ws://localhost:9292/');
        ws.onmessage = function(m) { show(m.data); };
      })();
    }
