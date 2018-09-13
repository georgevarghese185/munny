const spawn = require("child_process").spawn;

let port = "";
let host = "";

process.argv.map((arg, i, argv) => {
  if(arg === "--host") {
    host = "--host " + argv[i + 1];
  }

  if(arg === "--port") {
    port = "--port " + argv[i + 1];
  }
})

spawn("concurrently", [`pulp --watch build`, `webpack-dev-server --config build/config/webpack.dev.config.js ${host} ${port}`], {stdio: [0,1,2]});
