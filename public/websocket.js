// window.onload = function(){
//       (function(){
//         var show = function(el){
//           return function(msg){ el.innerHTML = msg; }
//         }(document.getElementById('alert'));
//         var ws       = new WebSocket('ws://localhost:9292/');
//         ws.onmessage = function(m) { show(m.data); };
//       })();
//     }


var ws       = new WebSocket('ws://localhost:9292/');

ws.onopen = () => {
  console.log('conectado');
};

ws.onerror = e => {
  console.log('error en la conexion', e);
};


ws.onmessage = e => {
  const msg = JSON.parse(e.data)
  console.log(msg);
  console.log(msg.alerta);
  console.log(msg.btn_Id);
  console.log(msg.item);
  console.log(msg.file);
  console.log(document.getElementById('checkeds'));
  console.log(document.getElementById(msg.item));
  if (msg.alerta){
    document.getElementById("alert").innerHTML=msg.alerta;
    document.getElementById(msg.btn_Id).style.visibility = "hidden";
    document.getElementById(msg.item).className = "record-box";
    document.getElementById('checkeds').appendChild(document.getElementById(msg.item));
  }
  else{
    document.getElementById("alert").innerHTML=msg;
    Materialize.toast('Hay una nueva notificación', 10000);
  }



  //console.log(e.data);
};

ws.onclose = () => {
  console.log('desconectado');
};
