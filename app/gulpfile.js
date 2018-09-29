const gulp = require('gulp');
const glob = require('glob');
const webpack = require('webpack-stream')
const VueLoaderPlugin = require('vue-loader/lib/plugin')
const fs = require('fs')
const path = require('path');
const spawn = require('child_process').spawn;

const PLUGINS_SOURCE = "src/plugins";


//Info required for building
const buildInfo = {
  plugins: [],

  //add the meta.json of all plugins to the `plugins` array
  init: async function() {
    let metaFiles = await getFiles(`${PLUGINS_SOURCE}/*/plugin.json`);
    this.plugins = await Promise.all(metaFiles.map(async (metaFile) => {
      let contents = await readFile(metaFile);
      return JSON.parse(contents);
    }));
  }
}


gulp.task('debug', ['init', 'webpack'])

gulp.task('webpack', ['init', 'purs-bundle'], function() {
  let entry = {}
  buildInfo.plugins.map(plugin => {
    if(plugin.build.type === "js") {
      entry[plugin.name] = `${__dirname}/${PLUGINS_SOURCE}/${plugin.name}/${plugin.entry}`
    } else {
      entry[plugin.name] = `${__dirname}/${PURS_PLUGINS_OUTPUT}/${plugin.name}/index.js`
    }
  })

  return gulp.src(['src/**/*.js', 'src/**/*.vue', `${PURS_PLUGINS_OUTPUT}/*/*.js`])
    .pipe(webpack({
      mode: 'development',
      entry,
      output: {
        path: path.resolve(__dirname, 'dist'),
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
    }))
    .pipe(gulp.dest('dist/'))
})

gulp.task('init', async function() {
  await buildInfo.init();
})

//======================= PURESCRIPT BUILD STEP ================================

const PULP_OUTPUT = 'output'
const PURS_PLUGINS_OUTPUT = 'output/_bundled';

gulp.task('purs-compile', ['init'], async function() {
  await spawnAndWait('pulp', ['build', '--build-path', `${PULP_OUTPUT}`]);
});

gulp.task('purs-bundle', ['purs-compile'], async function() {
  await Promise.all(
    buildInfo.plugins
      .filter(plugin => plugin.build.type === "purs")
      .map(async plugin => {
        await bundlePursPlugins(plugin.name, plugin.build.entry)
      }
  ))
})

const bundlePursPlugins = async (pluginName, pluginModule) => {
  await spawnAndWait('purs', ['bundle',
    `${PULP_OUTPUT}/**/*.js`,
    `--module`, `${pluginModule}`,
    '--main', pluginModule,
    `--output`, `${PURS_PLUGINS_OUTPUT}/${pluginName}/index.js`]);
}

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
const appendFile = async function(filePath, data) {
  return new Promise(function(resolve, reject) {
    fs.appendFile(filePath, data, (err, contents) => {
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
