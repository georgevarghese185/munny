const gulp = require('gulp');
const serve = require('gulp-serve')
const glob = require('glob');
const webpack = require('webpack')
const webpackStream = require('webpack-stream')
const WebpackDevServer = require('webpack-dev-server')
const VueLoaderPlugin = require('vue-loader/lib/plugin')
const fs = require('fs')
const path = require('path');
const spawn = require('child_process').spawn;
const mkdirp = require('mkdirp')


//======================== Constants and plugin info ============================

const SOURCE = "src"
const PLUGINS_SOURCE = `${SOURCE}/plugins`;
const OUTPUT = "dist";
const PURS_OUTPUT = 'output'
const PURS_PLUGINS_OUTPUT = 'output/_bundled';

//Meta data of all available plugins. Initialize using `initPlugins()`
var PLUGINS = []



//======================== Build Functions ====================================


// Initialize `PLUGINS` array with meta data of each plugin (taken from 'plugin_folder/plugin.json') and create meta.json file in output directory
const initPlugins = async function() {
  let metaFiles = await getFiles(`${PLUGINS_SOURCE}/*/plugin.json`);
  PLUGINS = await Promise.all(metaFiles.map(async (metaFile) => {
    let contents = await readFile(metaFile);
    return JSON.parse(contents);
  }));

  var meta = {
    plugins: PLUGINS
  }

  await writeFile(`${OUTPUT}/plugins.json`, JSON.stringify(meta, null, 2));
}

// Build the final bundled js files for each pluign
const webpackBuild = function(prod) {
  return gulp.src([`${SOURCE}/**/*.js`, `${SOURCE}/**/*.vue`, `${PURS_PLUGINS_OUTPUT}/*/*.js`])
    .pipe(webpackCompiler(webpackStream, prod))
    .on('error', function(err) {
      console.log(err);
      this.emit('end');
    })
    .pipe(gulp.dest(`${OUTPUT}/`))
}

// Start dev server to build plugins serve output folder
const webpackServe = function() {
  let compiler = webpackCompiler(webpack, false)

  let server = new WebpackDevServer(compiler, {
    contentBase: path.join(__dirname, `${OUTPUT}`)
  });
  server.listen(8080, "localhost", function(err) {
  		if(err) {
        console.error(err);
      }
	});
  return server;
}

// Returns a compiler object using the provided webpack function
const webpackCompiler = function(webpack, isProd) {
  let entry = {}
  PLUGINS.map(plugin => {
    if(plugin.build.type === "js") {
      entry[plugin.name] = `${__dirname}/${PLUGINS_SOURCE}/${plugin.name}/${plugin.build.entry}`
    } else {
      entry[plugin.name] = `${__dirname}/${PURS_PLUGINS_OUTPUT}/${plugin.name}`
    }
  });

  let config = {
    mode: isProd ? 'production' : 'development',
    entry,
    output: {
      path: path.resolve(__dirname, `${OUTPUT}`),
      filename: '[name]/index.js'
    },
    module:{
      rules: [
        {
          test: /\.vue$/,
          loader: 'vue-loader'
        },
        {
          test: /\.js$/,
          loader: 'babel-loader'
        },
        {
          test: /\.css$/,
          use: [
            'vue-style-loader',
            'css-loader'
          ]
        }
      ]
    },
    resolve: {
      modules: [
        "node_modules",
        __dirname
      ]
    },
    plugins: [
      new VueLoaderPlugin()
    ]
  }

  return webpack(config);
}

// Build all PureScript modules and bundle each purescript plugin
const buildPurescript = async function() {
  await compilePurescript();
  console.log("Bundling PureScript plugins...")
  await bundlePurescript();
  console.log("Bundled")
}

// Compile all purescript modules
const compilePurescript = async function() {
  await spawnAndWait('node_modules/.bin/pulp', ['build', '--build-path', `${PURS_OUTPUT}`]);
}

// Bundle all purescript plugins
const bundlePurescript = async function() {
  await Promise.all(
    PLUGINS
      .filter(plugin => plugin.build.type === "purs")
      .map(async plugin => {
        await spawnAndWait('node_modules/.bin/purs', ['bundle',
          `${PURS_OUTPUT}/**/*.js`,
          `--module`, `${plugin.build.entry}`,
          '--main', plugin.build.entry,
          `--output`, `${PURS_PLUGINS_OUTPUT}/${plugin.name}/index.js`]);
      }
  ))
}



//================================= Gulp Tasks ================================

//If webpack server is running, this will reference it (used for killing/restarting)
var server = null;

// initalize `PLUGINS` with all plugins meta data
gulp.task('init', initPlugins);

// Compile purescript modules without bundling plugins
gulp.task('purescript-compile', ['init'], compilePurescript);

// build purescript plugins
gulp.task('purescript-build', ['init'], buildPurescript);

// Build purescript plugins for debug (no bundling)
gulp.task('purescript-debug', ['init'], async function() {
  try { await compilePurescript(); } catch(e) { console.log(e); }
  await Promise.all(
    PLUGINS.filter(plugin => plugin.build.type === "purs")
    .map(plugin =>
      writeFile(`${PURS_PLUGINS_OUTPUT}/${plugin.name}/index.js`, `require('${PURS_OUTPUT}/${plugin.build.entry}').main();`)
    )
  );
})

//If webpack server is already running, kill it and start it again. (Useful when plugins are added, removed or modified at the plugin.json level)
gulp.task('restart-server', ['purescript-debug'], () => {
  console.log("\n\t RESTARTING WEBPACK...\n")
  if(server != null) {
    server.close();
  }
  server = webpackServe();
})

// Start webpack server and watch all purescript directories and plugin.json files for changes. Rebuild on change
gulp.task('debug', ['purescript-debug'], async () => {
  console.log("\n\n\t NOTE: If you find that webpack-dev-server is not rebuilding on file changes, try increasing your system's max file watch count\n\n")
  server = webpackServe();

  var pursDirs = []; //Directories containing purescript files
  let pursFiles = await getFiles(`${SOURCE}/**/*.purs`);
  pursFiles.map(file => {
    let dir = file.substring(0, file.lastIndexOf('/'));
    let glob = `${dir}/*`;
    if(pursDirs.indexOf(glob) == -1) pursDirs.push(glob); // Add without duplicates
  });

  gulp.watch(pursDirs, ['purescript-debug']) //Recompile purescript only on purescript related changes. (Leave other JS files to webpack)
  gulp.watch([`${PLUGINS_SOURCE}/*/plugin.json`], ['restart-server']) //If any plugin's plugin.json is modified, re-init and rebuild is required
})

// Build all plugins without optimizations (debug build without needing a server)
gulp.task('build-dev', ['purescript-build'], () => webpackBuild(false))

// Build all plugins for production
gulp.task('build-prod', ['purescript-build'], () => webpackBuild(true))



//================================ HELPERS =====================================


//Read a file as a promise (to use with async/await)
const readFile = async function(filePath) {
  return new Promise(function(resolve, reject) {
    fs.readFile(filePath, (err, contents) => {
      if(err) {
        reject(err);
      } else {
        resolve(contents);
      }
    })
  });
}

//Append to a file using a Promise (for async/await)
const writeFile = async function(filePath, data) {
  return new Promise(function(resolve, reject) {
    var dir = filePath.substring(0, filePath.lastIndexOf('/') + 1);
    mkdirp(dir, function(err) {
      if(err) {
        reject(err);
      } else {
        fs.writeFile(filePath, data, (err, contents) => {
          if(err) {
            reject(err);
          } else {
            resolve();
          }
        })
      }
    })
  });
}

//Given an array of source globs, return an array of file paths that match it
const getFiles = function(globs) {
  return new Promise(function(resolve, reject) {
    glob(globs, (er, files) => {
      if(er) {
        reject(er)
      } else {
        resolve(files)
      }
    })
  });
}

//Spawn a shell command and wait for it to complete
const spawnAndWait = async (command, args) => {
  await new Promise(function(resolve, reject) {
    let cmd = spawn(command, args, {stdio: 'inherit'});
    cmd.on('exit', code => {
      if(code == 0) {
        resolve();
      } else {
        reject(command + " failed: " + code);
      }
    })
  });
}
