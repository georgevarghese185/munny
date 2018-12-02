<template>

  <div class="home-screen">
    <NavBar :app="app" :title="app.name"/>
  </div>

</template>




<script>
  import NavBar from './widgets/NavBar.vue'

  export default {
    data: function(){
      return {
        app: {
          name: "Munny",
          pluginDir: "home"
        }
      }
    },
    components: {
      NavBar
    }
  }

</script>




<style scoped>

  .home-screen {
    position: absolute;
    width: 100%;
    height: 100%;
    background: #fbfbfb;
  }

</style>
