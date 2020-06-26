var ws       = new WebSocket('ws://localhost:9292/');
ws.onopen = () => {
  console.log('conectado');
};
ws.onerror = e => {
  console.log('error en la conexion', e);
};
ws.onmessage = e => {
  const msg = JSON.parse(e.data);
  document.getElementById("alert").innerHTML=msg;
};
ws.onclose = () => {
  console.log('desconectado');
};
