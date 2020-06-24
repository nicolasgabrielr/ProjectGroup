var ws       = new WebSocket('ws://localhost:9292/');
ws.onopen = () => {
  console.log('conectado');
};
ws.onerror = e => {
  console.log('error en la conexion', e);
};
ws.onmessage = e => {
  Materialize.toast('Tiene una nueva Notificacion', 10000)
  const msg = JSON.parse(e.data);
  document.getElementById("alert").innerHTML=msg;
};
ws.onclose = () => {
  console.log('desconectado');
};
