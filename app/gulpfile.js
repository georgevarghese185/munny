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



//======================== Constants and plugin info ============================


const PLUGINS_SOURCE = "src/plugins";
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

  await writeFile(`${OUTPUT}/meta.json`, JSON.stringify(meta, null, 2));
}

// Build the final bundled js files for each pluign
const webpackBuild = function(prod) {
  let entryPoints = {}
  PLUGINS.map(plugin => {
    if(plugin.build.type === "js") {
      entryPoints[plugin.name] = `${__dirname}/${PLUGINS_SOURCE}/${plugin.name}/${plugin.build.entry}`
    } else {
      entryPoints[plugin.name] = `${__dirname}/${PURS_PLUGINS_OUTPUT}/${plugin.name}/index.js`
    }
  });

  return gulp.src(['src/**/*.js', 'src/**/*.vue', `${PURS_PLUGINS_OUTPUT}/*/*.js`])
    .pipe(webpackCompiler(webpackStream, entryPoints, prod))
    .on('error', function(err) {
      console.log(err);
      this.emit('end');
    })
    .pipe(gulp.dest(`${OUTPUT}/`))
}

// Start dev server to build plugins serve output folder
const webpackServer = function() {
  let entryPoints = {}
  PLUGINS.map(plugin => {
    if(plugin.build.type === "js") {
      entryPoints[plugin.name] = `${__dirname}/${PLUGINS_SOURCE}/${plugin.name}/${plugin.build.entry}`
    } else {
      entryPoints[plugin.name] = `${__dirname}/${PURS_OUTPUT}/${plugin.build.entry}/index.js`
    }
  });

  let compiler = webpackCompiler(webpack, entryPoints, false)

  return new WebpackDevServer(compiler, {
      contentBase: path.join(__dirname, `${OUTPUT}`)
    })
    .listen(8080, "localhost", function(err) {
  		if(err) {
        console.error(err);
      }
	});
}

// Returns a compiler object using the provided webpack function
const webpackCompiler = function(webpack, entryPoints, isProd) {
  let config = {
    mode: isProd ? 'production' : 'development',
    entry: entryPoints,
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


// initalize `PLUGINS` with all plugins meta data
gulp.task('init', initPlugins);

// Compile purescript modules without bundling plugins
gulp.task('purescript-compile', ['init'], compilePurescript);

// build purescript plugins
gulp.task('purescript-build', ['init'], buildPurescript);

// build plugin js bundles without optimizations
gulp.task('webpack-build-dev', ['purescript-build'], () => webpackBuild(false));

// build plugin js bundles with optimizations
gulp.task('webpack-build', ['purescript-build'], () => webpackBuild(true));

// serve plugin js bundles
gulp.task('webpack-serve', ['purescript-compile'], () => {
  console.log("\n\n\t NOTE: If you find that webpack-dev-server is not rebuilding on file changes, try increasing your system's max file watch count\n\n")
  webpackServer()
});

// watch all purescript directories for changes. Rebuild purescript on change
gulp.task('watch', ['webpack-serve'], async () => {
  var watchDirs = [];
  let pursFiles = await getFiles('src/**/*.purs');
  pursFiles.map(file => {
    let dir = file.substring(0, file.lastIndexOf('/'));
    let glob = `${dir}/*`;
    if(watchDirs.indexOf(glob) == -1) watchDirs.push(glob);
  });
  return gulp.watch(watchDirs, ['purescript-compile'])
})

// Build and run debug server
gulp.task('debug', ['watch'])

// Build all plugins without optimizations (debug build without needing a server)
gulp.task('build-dev', ['webpack-build-dev'])

// Build all plugins for production
gulp.task('build-prod', ['webpack-build'])



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
    fs.writeFile(filePath, data, (err, contents) => {
      if(err) {
        reject(err);
      } else {
        resolve();
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
